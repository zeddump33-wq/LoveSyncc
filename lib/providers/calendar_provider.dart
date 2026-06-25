import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/database_service.dart';
import '../core/services/firestore_service.dart';
import '../models/event_model.dart';

class CalendarProvider extends ChangeNotifier {
  List<EventModel> _events = [];
  bool _isLoading = false;
  StreamSubscription? _eventsSubscription;

  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;

  void clear() {
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
    _events = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadEvents(String coupleId) async {
    _isLoading = true;
    notifyListeners();

    final data = await DatabaseService.query(
      'events',
      where: 'coupleId = ?',
      whereArgs: [coupleId],
      orderBy: 'date ASC',
    );
    _events = data.map((e) => EventModel.fromMap(e)).toList();

    _isLoading = false;
    notifyListeners();

    // Listen for real-time updates from Firestore
    _eventsSubscription?.cancel();
    try {
      _eventsSubscription = FirestoreService.streamEvents(coupleId).listen((data) {
        final firestoreEvents = data.map((e) => EventModel.fromMap(e)).toList();
        final firestoreIds = firestoreEvents.map((e) => e.id).toSet();
        _events = [
          ..._events.where((e) => !firestoreIds.contains(e.id)),
          ...firestoreEvents,
        ]..sort((a, b) => a.date.compareTo(b.date));
        notifyListeners();
      }, onError: (_) {});
    } catch (e) {
      print('Firestore streamEvents failed: $e');
    }
  }

  Future<void> addEvent(EventModel event) async {
    String? firestoreId;
    try {
      firestoreId = await FirestoreService.addEvent(event.coupleId, event.toMap());
    } catch (e) {
      print('Firestore addEvent failed: $e');
    }
    final model = EventModel(
      id: firestoreId ?? event.id,
      coupleId: event.coupleId,
      title: event.title,
      date: event.date,
      time: event.time,
      description: event.description,
      type: event.type,
      createdAt: event.createdAt,
      createdBy: event.createdBy,
    );
    await DatabaseService.insert('events', model.toMap());
    _events.add(model);
    _events.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }

  Future<void> updateEvent(EventModel event) async {
    await DatabaseService.update('events', event.toMap(), event.id);
    try {
      await FirestoreService.updateEvent(event.coupleId, event.id, event.toMap());
    } catch (e) {
      print('Firestore updateEvent failed: $e');
    }
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String id) async {
    await DatabaseService.delete('events', id);
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  List<EventModel> getEventsForDate(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    return _events.where((e) => e.date == dateStr).toList();
  }

  List<EventModel> get upcomingEvents {
    final now = DateTime.now().toIso8601String().split('T')[0];
    return _events.where((e) => e.date.compareTo(now) >= 0).take(5).toList();
  }
}
