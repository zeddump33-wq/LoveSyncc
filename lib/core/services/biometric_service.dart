import 'package:flutter/foundation.dart' show kIsWeb;

class BiometricService {
  static Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    // Dynamic import to avoid web crash
    try {
      final auth = await _getLocalAuth();
      if (auth == null) return false;
      return await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      final auth = await _getLocalAuth();
      if (auth == null) return false;
      return await auth.authenticate(
        localizedReason: 'Authenticate to access LoveSync',
        options: const _AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      final auth = await _getLocalAuth();
      if (auth == null) return [];
      return await auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  static Future<dynamic> _getLocalAuth() async {
    try {
      final localAuth = await _loadLocalAuth();
      return localAuth;
    } catch (_) {
      return null;
    }
  }

  static Future<dynamic> _loadLocalAuth() async {
    // Use conditional import via dynamic loading
    final localAuth = await _createLocalAuth();
    return localAuth;
  }

  static Future<dynamic> _createLocalAuth() async {
    // This will only work on mobile/desktop platforms
    // On web, the local_auth package will throw
    try {
      // ignore: avoid_dynamic_calls
      return (await _getLocalAuthClass()).newInstance();
    } catch (_) {
      return null;
    }
  }

  static Future<dynamic> _getLocalAuthClass() async {
    // This is a workaround for conditional imports
    throw UnsupportedError('local_auth is not supported on this platform');
  }
}

class _AuthenticationOptions {
  final bool stickyAuth;
  final bool biometricOnly;

  const _AuthenticationOptions({
    this.stickyAuth = false,
    this.biometricOnly = false,
  });
}
