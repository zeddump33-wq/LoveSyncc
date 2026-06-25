import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/services/database_service.dart';
import '../core/services/firestore_service.dart';
import '../core/utils/date_utils.dart';
import '../models/message_model.dart';
import '../core/services/auth_service.dart';
import '../core/services/image_upload_service.dart';

class ChatProvider extends ChangeNotifier {
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isPartnerTyping = false;
  
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _coupleSubscription;
  final _uuid = const Uuid();

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isPartnerTyping => _isPartnerTyping;

  Future<void> loadMessages(String coupleId) async {
    _isLoading = true;
    notifyListeners();

    // Load local first for speed, DESC order so index 0 is newest
    final localData = await DatabaseService.query(
      'messages',
      where: 'coupleId = ?',
      whereArgs: [coupleId],
      orderBy: 'createdAt DESC',
    );
    _messages = localData.map((m) => MessageModel.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();

    // Listen for real-time updates from Firestore (if available)
    _messagesSubscription?.cancel();
    try {
      _messagesSubscription = FirestoreService.streamMessages(coupleId).listen((data) {
        final firestoreMessages = data.map((m) => MessageModel.fromMap(m)).toList();
        final firestoreIds = firestoreMessages.map((m) => m.id).toSet();
        
        // Remove items that exist in both from the local list, keep the incoming firestore version
        _messages = [
          ..._messages.where((m) => !firestoreIds.contains(m.id)),
          ...firestoreMessages,
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // DESC sort
        notifyListeners();
      }, onError: (_) {});
    } catch (e) {
      print('Firestore streamMessages failed: $e');
    }

    // Listen for typing status
    _coupleSubscription?.cancel();
    try {
      final currentUser = AuthService.currentUser;
      _coupleSubscription = FirestoreService.streamCouple(coupleId).listen((data) {
        if (data != null && currentUser != null) {
          final partnerId = data['partner1Id'] == currentUser.id ? data['partner2Id'] : data['partner1Id'];
          if (partnerId != null) {
            final typingStatus = data['typing_$partnerId'] ?? false;
            if (_isPartnerTyping != typingStatus) {
              _isPartnerTyping = typingStatus;
              notifyListeners();
            }
          }
        }
      });
    } catch (e) {
      print('Firestore streamCouple failed: $e');
    }
  }

  Future<void> updateTyping(String coupleId, bool isTyping) async {
    final user = AuthService.currentUser;
    if (user != null) {
      await FirestoreService.updateTypingStatus(coupleId, user.id, isTyping);
    }
  }

  Future<void> sendMessage({
    required String coupleId,
    String? text,
    String? imagePath,
    String? voicePath,
    int? voiceDuration,
    String? emoji,
    String type = 'text',
    String? replyToId,
    String? replyToText,
    String? replyToType,
  }) async {
    if (_isSending) return; // Prevent double send
    
    final user = AuthService.currentUser;
    if (user == null) return;

    _isSending = true;
    notifyListeners();

    try {
      final now = DateFormatUtils.formatDateTime(DateTime.now());
      final messageId = _uuid.v4(); // Generate UUID on client
      
      final messageData = {
        'id': messageId,
        'coupleId': coupleId,
        'senderId': user.id,
        'text': text,
        'imagePath': imagePath,
        'voicePath': voicePath,
        'voiceDuration': voiceDuration,
        'emoji': emoji,
        'type': type,
        'createdAt': now,
        'replyToId': replyToId,
        'replyToText': replyToText,
        'replyToType': replyToType,
        'isRead': 0,
      };

      final messageModel = MessageModel.fromMap(messageData);
      
      // Save locally first for instant UI feedback
      await DatabaseService.insert('messages', messageModel.toMap());
      if (!_messages.any((m) => m.id == messageId)) {
        _messages.insert(0, messageModel); // Insert at 0 because it's DESC
        notifyListeners();
      }

      // Send to Firestore
      await FirestoreService.sendMessage(coupleId, messageData);
      
      // Stop typing
      await updateTyping(coupleId, false);
    } catch (e) {
      print('Firestore sendMessage failed: $e');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> sendImage(String coupleId, String imagePath) async {
    final remoteUrl = await ImageUploadService.uploadImage(imagePath);
    if (remoteUrl != null) {
      await sendMessage(coupleId: coupleId, imagePath: remoteUrl, type: 'image');
    } else {
      print('Failed to upload image. Cannot send.');
    }
  }

  Future<void> sendVoice(String coupleId, String voicePath, int duration) async {
    await sendMessage(coupleId: coupleId, voicePath: voicePath, voiceDuration: duration, type: 'voice');
  }

  Future<void> sendEmoji(String coupleId, String emoji) async {
    await sendMessage(coupleId: coupleId, emoji: emoji, type: 'emoji');
  }

  void clear() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _coupleSubscription?.cancel();
    _coupleSubscription = null;
    _messages = [];
    _isPartnerTyping = false;
    notifyListeners();
  }

  int get unreadCount {
    final user = AuthService.currentUser;
    if (user == null) return 0;
    return _messages.where((m) => m.senderId != user.id && m.isRead == 0).length;
  }

  Future<void> markAsRead(String messageId) async {
    await DatabaseService.update('messages', {'isRead': 1}, messageId);
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = MessageModel.fromMap({..._messages[index].toMap(), 'isRead': 1});
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    bool changed = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].senderId != user.id && _messages[i].isRead == 0) {
        await DatabaseService.update('messages', {'isRead': 1}, _messages[i].id);
        _messages[i] = MessageModel.fromMap({..._messages[i].toMap(), 'isRead': 1});
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}
