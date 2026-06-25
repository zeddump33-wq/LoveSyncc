import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/database_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/partner_service.dart';
import '../models/couple_model.dart';
import '../models/user_model.dart';
import '../models/milestone_model.dart';

class CoupleProvider extends ChangeNotifier {
  CoupleModel? _couple;
  List<UserModel> _members = [];
  List<MilestoneModel> _milestones = [];
  bool _isLoading = false;
  StreamSubscription? _milestonesSubscription;

  CoupleModel? get couple => _couple;
  List<UserModel> get members => _members;
  List<MilestoneModel> get milestones => _milestones;
  bool get isLoading => _isLoading;
  bool get isLinked => _couple?.status == 'active' && _couple?.partner2Id != null;

  Future<void> loadCouple(String coupleId) async {
    _isLoading = true;
    notifyListeners();

    _couple = await PartnerService.getCouple(coupleId);
    if (_couple != null) {
      _members = await PartnerService.getCoupleMembers(coupleId);
      _loadMilestones(coupleId);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> createCouple(String anniversaryDate) async {
    final couple = await PartnerService.createCouple(anniversaryDate);
    if (couple != null) {
      _couple = couple;
      _members = await PartnerService.getCoupleMembers(couple.id);
      notifyListeners();
      return couple.inviteCode;
    }
    return null;
  }

  Future<bool> joinCouple(String inviteCode) async {
    final couple = await PartnerService.joinCouple(inviteCode);
    if (couple != null) {
      _couple = couple;
      _members = await PartnerService.getCoupleMembers(couple.id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> updateAnniversary(String date) async {
    if (_couple == null) return;
    await PartnerService.updateAnniversary(_couple!.id, date);
    _couple = await PartnerService.getCouple(_couple!.id);
    notifyListeners();
  }

  Future<void> addMilestone(MilestoneModel milestone) async {
    await DatabaseService.insert('milestones', milestone.toMap());
    try {
      await FirestoreService.addMilestone(_couple!.id, milestone.toMap());
    } catch (e) {
      print('Firestore addMilestone failed: $e');
    }
    _milestones.add(milestone);
    notifyListeners();
  }

  void _loadMilestones(String coupleId) {
    // Load local first for speed
    DatabaseService.query(
      'milestones',
      where: 'coupleId = ?',
      whereArgs: [coupleId],
      orderBy: 'date DESC',
    ).then((data) {
      _milestones = data.map((m) => MilestoneModel.fromMap(m)).toList();
      notifyListeners();
      _autoCreateMissingMilestones(coupleId);
    });

    // Listen for real-time updates from Firestore
    _milestonesSubscription?.cancel();
    try {
      _milestonesSubscription = FirestoreService.streamMilestones(coupleId).listen((data) {
        _milestones = data.map((m) => MilestoneModel.fromMap(m)).toList();
        notifyListeners();
      }, onError: (_) {});
    } catch (e) {
      print('Firestore streamMilestones failed: $e');
    }
  }

  Future<void> _autoCreateMissingMilestones(String coupleId) async {
    if (_couple?.anniversaryDate == null) return;
    final anniv = DateTime.parse(_couple!.anniversaryDate!);
    final now = DateTime.now();
    final existingTitles = _milestones.map((m) => m.title).toSet();

    final milestonesToCreate = <Map<String, String?>>[];
    for (int month = 1; month <= 12; month++) {
      final milestoneDate = DateTime(anniv.year, anniv.month + month, anniv.day);
      if (milestoneDate.isAfter(now)) break;

      final title = month == 1
          ? '1 Month Together'
          : month == 3
              ? '3 Months Together'
              : month == 6
                  ? 'Half Year Together'
                  : month == 9
                      ? '9 Months Together'
                      : month == 12
                          ? '1 Year Together'
                          : null;
      if (title != null && !existingTitles.contains(title)) {
        milestonesToCreate.add({
          'title': title,
          'date': '${milestoneDate.year}-${milestoneDate.month.toString().padLeft(2, '0')}-${milestoneDate.day.toString().padLeft(2, '0')}',
          'icon': month == 1
              ? 'favorite'
              : month == 3
                  ? 'celebration'
                  : month == 6
                      ? 'diamond'
                      : month == 9
                          ? 'stars'
                          : month == 12
                              ? 'cake'
                              : null,
        });
      }
    }

    final years = now.year - anniv.year;
    for (int y = 2; y <= years; y++) {
      final title = '$y Years Together!';
      if (!existingTitles.contains(title)) {
        final date = DateTime(anniv.year + y, anniv.month, anniv.day);
        milestonesToCreate.add({
          'title': title,
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'icon': 'celebration',
        });
      }
    }

    for (final m in milestonesToCreate) {
      final milestone = MilestoneModel(
        id: DateTime.now().millisecondsSinceEpoch.toString() + m['title']!,
        coupleId: coupleId,
        title: m['title']!,
        date: m['date']!,
        icon: m['icon'],
        createdAt: DateTime.now().toIso8601String(),
      );
      await DatabaseService.insert('milestones', milestone.toMap());
      try {
        await FirestoreService.addMilestone(coupleId, milestone.toMap());
      } catch (e) {
        print('Firestore addMilestone (auto) failed: $e');
      }
      _milestones.add(milestone);
    }
    if (milestonesToCreate.isNotEmpty) notifyListeners();
  }

  Future<void> unlinkPartner() async {
    await PartnerService.unlinkPartner();
    _couple = null;
    _members = [];
    _milestones = [];
    notifyListeners();
  }

  void clear() {
    _milestonesSubscription?.cancel();
    _milestonesSubscription = null;
    _couple = null;
    _members = [];
    _milestones = [];
    notifyListeners();
  }

  UserModel? get partner {
    if (_members.isEmpty) return null;
    return _members.length > 1 ? _members[1] : null;
  }

  int get daysTogether {
    if (_couple?.anniversaryDate == null) return 0;
    final anniversary = DateTime.parse(_couple!.anniversaryDate!);
    return DateTime.now().difference(anniversary).inDays;
  }
}
