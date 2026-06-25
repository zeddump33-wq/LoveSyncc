import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/services/database_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/image_upload_service.dart';
import '../models/memory_model.dart';

class MemoriesProvider extends ChangeNotifier {
  List<MemoryModel> _memories = [];
  List<MemoryAlbumModel> _albums = [];
  bool _isLoading = false;
  bool _isToggling = false;
  StreamSubscription? _memoriesSubscription;
  final _uuid = const Uuid();

  List<MemoryModel> get memories => _memories;
  List<MemoryAlbumModel> get albums => _albums;
  bool get isLoading => _isLoading;

  void clear() {
    _memoriesSubscription?.cancel();
    _memoriesSubscription = null;
    _memories = [];
    _albums = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMemories(String coupleId) async {
    _isLoading = true;
    notifyListeners();

    final data = await DatabaseService.query(
      'memories',
      where: 'coupleId = ?',
      whereArgs: [coupleId],
      orderBy: 'createdAt DESC',
    );
    _memories = data.map((m) => MemoryModel.fromMap(m)).toList();

    final albumData = await DatabaseService.query(
      'memory_albums',
      where: 'coupleId = ?',
      whereArgs: [coupleId],
      orderBy: 'createdAt DESC',
    );
    _albums = albumData.map((a) => MemoryAlbumModel.fromMap(a)).toList();

    _isLoading = false;
    notifyListeners();

    // Listen for real-time updates from Firestore
    _memoriesSubscription?.cancel();
    try {
      _memoriesSubscription = FirestoreService.streamMemories(coupleId).listen((data) {
        final firestoreMemories = data.map((m) => MemoryModel.fromMap(m)).toList();
        final firestoreIds = firestoreMemories.map((m) => m.id).toSet();
        
        _memories = [
          ..._memories.where((m) => !firestoreIds.contains(m.id)),
          ...firestoreMemories,
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }, onError: (_) {});
    } catch (e) {
      print('Firestore streamMemories failed: $e');
    }
  }

  Future<void> addMemory(MemoryModel memory) async {
    String? imageUrl = memory.imagePath;

    // Upload to ImgBB if it's a local file path
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      final uploadedUrl = await ImageUploadService.uploadImage(imageUrl);
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      }
    }

    final memoryId = _uuid.v4();
    final model = MemoryModel(
      id: memoryId,
      coupleId: memory.coupleId,
      albumId: memory.albumId,
      imagePath: imageUrl,
      caption: memory.caption,
      date: memory.date,
      isFavorite: memory.isFavorite,
      createdAt: memory.createdAt,
    );

    // Save local
    await DatabaseService.insert('memories', model.toMap());
    _memories.insert(0, model);
    notifyListeners();

    // Sync to Firestore
    try {
      await FirestoreService.addMemory(model.coupleId, model.toMap());
    } catch (e) {
      print('Firestore addMemory failed: $e');
    }
  }

  Future<void> deleteMemory(String id) async {
    await DatabaseService.delete('memories', id);
    _memories.removeWhere((m) => m.id == id);
    notifyListeners();
    // In a full implementation, you should also delete from Firestore here
  }

  Future<void> toggleFavorite(String id) async {
    if (_isToggling) return;
    _isToggling = true;

    try {
      final index = _memories.indexWhere((m) => m.id == id);
      if (index != -1) {
        final newValue = _memories[index].isFavorite == 0 ? 1 : 0;
        await DatabaseService.update('memories', {'isFavorite': newValue}, id);
        _memories[index] = MemoryModel.fromMap({..._memories[index].toMap(), 'isFavorite': newValue});
        notifyListeners();

        try {
          await FirestoreService.addMemory(_memories[index].coupleId, _memories[index].toMap());
        } catch (e) {
          print('Firestore sync toggleFavorite failed: $e');
        }
      }
    } finally {
      _isToggling = false;
    }
  }

  Future<void> createAlbum(MemoryAlbumModel album) async {
    final albumId = _uuid.v4();
    final newAlbum = MemoryAlbumModel.fromMap({...album.toMap(), 'id': albumId});
    
    await DatabaseService.insert('memory_albums', newAlbum.toMap());
    _albums.insert(0, newAlbum);
    notifyListeners();
  }

  List<MemoryModel> get favorites => _memories.where((m) => m.isFavorite == 1).toList();

  List<MemoryModel> getAlbumMemories(String albumId) {
    return _memories.where((m) => m.albumId == albumId).toList();
  }
}
