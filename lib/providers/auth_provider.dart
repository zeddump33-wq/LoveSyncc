import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await AuthService.restoreSession();
      _user = AuthService.currentUser;
    } catch (e) {
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createLocalAccount(String name) async {
    _isLoading = true;
    notifyListeners();

    final success = await AuthService.createLocalAccount(name);
    if (success) {
      _user = AuthService.currentUser;
      _isLoggedIn = true;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await AuthService.loginWithEmail(email, password);
    if (success) {
      _user = AuthService.currentUser;
      _isLoggedIn = true;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> registerWithEmail(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await AuthService.registerWithEmail(name, email, password);
    if (success) {
      _user = AuthService.currentUser;
      _isLoggedIn = true;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    final success = await AuthService.loginWithGoogle();
    if (success) {
      _user = AuthService.currentUser;
      _isLoggedIn = true;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> clearSession() async {
    await AuthService.clearSession();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> updateProfile(String name, {String? photoPath}) async {
    await AuthService.updateProfile(name, photoPath: photoPath);
    _user = AuthService.currentUser;
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    final success = await AuthService.restoreSession();
    if (success) {
      _user = AuthService.currentUser;
      _isLoggedIn = true;
    }
    return success;
  }

  Future<bool> hasPinCode() async {
    return StorageService.getPinCode() != null;
  }

  Future<bool> verifyPin(String pin) async {
    return StorageService.getPinCode() == pin;
  }

  Future<void> setPinCode(String pin) async {
    await StorageService.setPinCode(pin);
  }
}
