import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe_to/swipe_to.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/services/file_storage_service.dart' as file_storage;
import '../../core/utils/date_utils.dart';
import '../../core/utils/platform_image_loader.dart';
import '../../core/widgets/responsive_shell.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/couple_provider.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});
  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _loaded = false;
  MessageModel? _replyingTo;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMessages());
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final couple = context.read<CoupleProvider>().couple;
    if (couple == null) return;
    
    // Set typing to true
    context.read<ChatProvider>().updateTyping(couple.id, true);
    
    // Stop typing after 3 seconds of inactivity
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.read<ChatProvider>().updateTyping(couple.id, false);
      }
    });
  }

  Future<void> _loadMessages() async {
    final couple = context.read<CoupleProvider>();
    if (couple.couple != null) {
      _loaded = true;
      await context.read<ChatProvider>().loadMessages(couple.couple!.id);
    }
  }

  double _bubbleMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 560;
    if (width >= 900) return 480;
    if (width >= 600) return width * 0.68;
    return width * 0.82;
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    final coupleId = context.read<CoupleProvider>().couple?.id;
    if (coupleId != null) {
      context.read<ChatProvider>().updateTyping(coupleId, false);
    }
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    final couple = context.read<CoupleProvider>();
    if (couple.couple == null) return;

    final replyId = _replyingTo?.id;
    final replyText = _replyingTo?.type == 'text'
        ? _replyingTo?.text
        : (_replyingTo?.type == 'image' ? 'Image' : 'Media');
    final replyType = _replyingTo?.type;
    _cancelReply();

    await context.read<ChatProvider>().sendMessage(
          coupleId: couple.couple!.id,
          text: text,
          replyToId: replyId,
          replyToText: replyText,
          replyToType: replyType,
        );
  }

  Future<void> _sendImage() async {
    final path = await file_storage.FileStorageService.pickAndSaveImage();
    if (path == null) return;
    final couple = context.read<CoupleProvider>();
    if (couple.couple == null) return;
    await context.read<ChatProvider>().sendImage(couple.couple!.id, path);
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 0, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2B2B2B)
              : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 12,
              child: Center(
                child: Text('...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Consumer<CoupleProvider>(
          builder: (_, couple, __) => Column(
            children: [
              Text(
                couple.partner?.name ?? 'My Love',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '${couple.daysTogether} days together',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFFDF2F8), const Color(0xFFFFF5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ResponsiveShell(
          maxContentWidth: 1120,
          child: Column(
            children: [
              Expanded(
                child: Consumer2<ChatProvider, CoupleProvider>(
                  builder: (_, chat, couple, __) {
                    if (!_loaded && couple.couple != null) {
                      _loaded = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _loadMessages();
                      });
                    }
                    if (chat.messages.isNotEmpty && chat.unreadCount > 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        chat.markAllAsRead();
                      });
                    }
                    if (chat.messages.isEmpty && !chat.isPartnerTyping) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite, size: 48, color: ThemeConstants.primaryColor.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text('Start your conversation', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      );
                    }
                    
                    final itemCount = chat.messages.length + (chat.isPartnerTyping ? 1 : 0);
                    
                    return ListView.builder(
                      reverse: true, // Newest messages at the bottom automatically
                      padding: const EdgeInsets.all(16),
                      itemCount: itemCount,
                      itemBuilder: (_, i) {
                        if (chat.isPartnerTyping && i == 0) {
                          return _buildTypingIndicator();
                        }
                        final msgIndex = chat.isPartnerTyping ? i - 1 : i;
                        final msg = chat.messages[msgIndex];
                        return SwipeTo(
                          onRightSwipe: (_) {
                            setState(() {
                              _replyingTo = msg;
                              _focusNode.requestFocus();
                            });
                          },
                          child: _buildMessage(msg),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(MessageModel message) {
    final auth = context.read<AuthProvider>();
    final isMe = message.senderId == auth.user?.id;
    final radius = const Radius.circular(20);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        constraints: BoxConstraints(maxWidth: _bubbleMaxWidth(context)),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.replyToId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: ThemeConstants.primaryColor, width: 4),
                  ),
                ),
                child: Text(
                  message.replyToText ?? 'Replied message',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (message.type == 'image' && message.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: message.imagePath!.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: message.imagePath!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 80),
                      )
                    : message.imagePath!.startsWith('data:')
                        ? Image.memory(
                            base64Decode(message.imagePath!.split(',').last),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
                          )
                        : kIsWeb
                            ? Image.network(
                                message.imagePath!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
                              )
                            : platformImageWidget(
                                message.imagePath!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
                              ),
              )
            else if (message.type == 'voice')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFF0084FF)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2B2B2B)
                          : const Color(0xFFE8E8E8)),
                  borderRadius: BorderRadius.only(
                    topLeft: radius,
                    topRight: radius,
                    bottomLeft: isMe ? radius : Radius.zero,
                    bottomRight: isMe ? Radius.zero : radius,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: isMe ? Colors.white : ThemeConstants.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voice message',
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${message.voiceDuration ?? 0}s',
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else if (message.type == 'emoji')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  message.emoji ?? '❤️',
                  style: const TextStyle(fontSize: 48),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFF0084FF)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2B2B2B)
                          : const Color(0xFFE8E8E8)),
                  borderRadius: BorderRadius.only(
                    topLeft: radius,
                    topRight: radius,
                    bottomLeft: isMe ? radius : Radius.zero,
                    bottomRight: isMe ? Radius.zero : radius,
                  ),
                ),
                child: Text(
                  message.text ?? '',
                  style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87),
                    fontSize: 15,
                  ),
                ),
              ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                DateFormatUtils.timeAgo(
                  DateFormatUtils.parseDateTime(message.createdAt),
                ),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Column(
      children: [
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black.withOpacity(0.05),
            child: Row(
              children: [
                Icon(Icons.reply, color: ThemeConstants.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Replying to message',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        _replyingTo!.type == 'text' ? _replyingTo!.text! : 'Media',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _cancelReply,
                ),
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F3460)
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined, color: ThemeConstants.primaryColor),
                onPressed: _sendImage,
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                  minLines: 1,
                ),
              ),
              Consumer<ChatProvider>(
                builder: (_, chat, __) => IconButton(
                  icon: chat.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, color: ThemeConstants.primaryColor),
                  onPressed: chat.isSending ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
