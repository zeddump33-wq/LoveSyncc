import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/database_service.dart';
import '../core/services/firestore_service.dart';
import '../models/wishlist_model.dart';

class WishlistProvider extends ChangeNotifier {
  List<WishlistModel> _wishlist = [];
  bool _isLoading = false;
  StreamSubscription? _wishlistSubscription;

  List<WishlistModel> get wishlist => _wishlist;
  bool get isLoading => _isLoading;

  void clear() {
    _wishlistSubscription?.cancel();
    _wishlistSubscription = null;
    _wishlist = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadWishlist(String coupleId) async {
    _isLoading = true;
    notifyListeners();

    final data = await DatabaseService.query(
      'wishlist',
      where: 'coupleId = ?',
      whereArgs: [coupleId],
      orderBy: 'createdAt DESC',
    );
    _wishlist = data.map((w) => WishlistModel.fromMap(w)).toList();

    _isLoading = false;
    notifyListeners();

    // Listen for real-time updates from Firestore
    _wishlistSubscription?.cancel();
    try {
      _wishlistSubscription = FirestoreService.streamWishlist(coupleId).listen((data) {
        final firestoreItems = data.map((w) => WishlistModel.fromMap(w)).toList();
        final firestoreIds = firestoreItems.map((w) => w.id).toSet();
        _wishlist = [
          ..._wishlist.where((w) => !firestoreIds.contains(w.id)),
          ...firestoreItems,
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }, onError: (_) {});
    } catch (e) {
      print('Firestore streamWishlist failed: $e');
    }
  }

  Future<void> addItem(WishlistModel item) async {
    String? firestoreId;
    try {
      firestoreId = await FirestoreService.addWishlistItem(item.coupleId, item.toMap());
    } catch (e) {
      print('Firestore addWishlistItem failed: $e');
    }
    final model = WishlistModel(
      id: firestoreId ?? item.id,
      coupleId: item.coupleId,
      title: item.title,
      description: item.description,
      price: item.price,
      imagePath: item.imagePath,
      link: item.link,
      isReserved: item.isReserved,
      reservedBy: item.reservedBy,
      isPurchased: item.isPurchased,
      createdAt: item.createdAt,
      createdBy: item.createdBy,
    );
    await DatabaseService.insert('wishlist', model.toMap());
    _wishlist.insert(0, model);
    notifyListeners();
  }

  Future<void> toggleReserved(String id, String userId) async {
    final index = _wishlist.indexWhere((w) => w.id == id);
    if (index != -1) {
      final item = _wishlist[index];
      final isReserved = item.isReserved == 0 ? 1 : 0;
      final reservedBy = isReserved == 1 ? userId : null;
      await DatabaseService.update('wishlist', {
        'isReserved': isReserved,
        'reservedBy': reservedBy,
      }, id);
      try {
        await FirestoreService.updateWishlistItem(item.coupleId, id, {
          'isReserved': isReserved,
          'reservedBy': reservedBy,
        });
      } catch (e) {
        print('Firestore updateWishlistItem failed: $e');
      }
      _wishlist[index] = WishlistModel(
        id: item.id,
        coupleId: item.coupleId,
        title: item.title,
        description: item.description,
        price: item.price,
        imagePath: item.imagePath,
        link: item.link,
        isReserved: isReserved,
        reservedBy: reservedBy,
        isPurchased: item.isPurchased,
        createdAt: item.createdAt,
        createdBy: item.createdBy,
      );
      notifyListeners();
    }
  }

  Future<void> togglePurchased(String id) async {
    final index = _wishlist.indexWhere((w) => w.id == id);
    if (index != -1) {
      final item = _wishlist[index];
      final isPurchased = item.isPurchased == 0 ? 1 : 0;
      await DatabaseService.update('wishlist', {'isPurchased': isPurchased}, id);
      try {
        await FirestoreService.updateWishlistItem(item.coupleId, id, {
          'isPurchased': isPurchased,
        });
      } catch (e) {
        print('Firestore updateWishlistItem failed: $e');
      }
      _wishlist[index] = WishlistModel(
        id: item.id,
        coupleId: item.coupleId,
        title: item.title,
        description: item.description,
        price: item.price,
        imagePath: item.imagePath,
        link: item.link,
        isReserved: item.isReserved,
        reservedBy: item.reservedBy,
        isPurchased: isPurchased,
        createdAt: item.createdAt,
        createdBy: item.createdBy,
      );
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    await DatabaseService.delete('wishlist', id);
    _wishlist.removeWhere((w) => w.id == id);
    notifyListeners();
  }
}
