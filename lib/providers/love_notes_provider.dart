import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/database_service.dart';
import '../core/services/firestore_service.dart';
import '../models/love_note_model.dart';

class LoveNotesProvider extends ChangeNotifier {
  List<LoveNoteModel> _notes = [];
  bool _isLoading = false;
  bool _isToggling = false;
  StreamSubscription? _notesSubscription;

  List<LoveNoteModel> get notes => _notes;
  bool get isLoading => _isLoading;

  void clear() {
    _notesSubscription?.cancel();
    _notesSubscription = null;
    _notes = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNotes(String coupleId) async {
    _isLoading = true;
    notifyListeners();

    final data = await DatabaseService.query(
      'love_notes',
      where: 'coupleId = ?',
      whereArgs: [coupleId],
      orderBy: 'createdAt DESC',
    );
    _notes = data.map((n) => LoveNoteModel.fromMap(n)).toList();

    _isLoading = false;
    notifyListeners();

    // Listen for real-time updates from Firestore
    _notesSubscription?.cancel();
    try {
      _notesSubscription = FirestoreService.streamNotes(coupleId).listen((data) {
        final firestoreNotes = data.map((n) => LoveNoteModel.fromMap(n)).toList();
        final firestoreIds = firestoreNotes.map((n) => n.id).toSet();
        _notes = [
          ..._notes.where((n) => !firestoreIds.contains(n.id)),
          ...firestoreNotes,
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }, onError: (_) {});
    } catch (e) {
      print('Firestore streamNotes failed: $e');
    }
  }

  Future<void> addNote(LoveNoteModel note) async {
    String? firestoreId;
    try {
      firestoreId = await FirestoreService.addNote(note.coupleId, note.toMap());
    } catch (e) {
      print('Firestore addNote failed: $e');
    }
    final model = LoveNoteModel(
      id: firestoreId ?? note.id,
      coupleId: note.coupleId,
      senderId: note.senderId,
      title: note.title,
      content: note.content,
      type: note.type,
      scheduledDate: note.scheduledDate,
      isDelivered: note.isDelivered,
      isFavorite: note.isFavorite,
      createdAt: note.createdAt,
    );
    await DatabaseService.insert('love_notes', model.toMap());
    _notes.insert(0, model);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    if (_isToggling) return;
    _isToggling = true;

    try {
      final index = _notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        final newValue = _notes[index].isFavorite == 0 ? 1 : 0;
        await DatabaseService.update('love_notes', {'isFavorite': newValue}, id);
        _notes[index] = LoveNoteModel(
          id: _notes[index].id,
          coupleId: _notes[index].coupleId,
          senderId: _notes[index].senderId,
          title: _notes[index].title,
          content: _notes[index].content,
          type: _notes[index].type,
          scheduledDate: _notes[index].scheduledDate,
          isDelivered: _notes[index].isDelivered,
          isFavorite: newValue,
          createdAt: _notes[index].createdAt,
        );
        notifyListeners();

        try {
          await FirestoreService.updateNote(_notes[index].coupleId, id, {'isFavorite': newValue});
        } catch (e) {
          print('Firestore updateNote toggleFavorite failed: $e');
        }
      }
    } finally {
      _isToggling = false;
    }
  }

  Future<void> deleteNote(String id) async {
    await DatabaseService.delete('love_notes', id);
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  List<LoveNoteModel> get favorites => _notes.where((n) => n.isFavorite == 1).toList();
  List<LoveNoteModel> get futureMessages => _notes.where((n) => n.type == 'future').toList();
}
