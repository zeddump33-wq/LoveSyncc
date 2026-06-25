import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class HiveService {
  static Box? _box;

  static Future<void> init() async {
    if (kIsWeb) {
      // On web, Hive uses IndexedDB adapter automatically with hive_web
      await Hive.initFlutter();
    } else {
      await Hive.initFlutter();
    }
    _box = await Hive.openBox(AppConstants.hiveBoxName);
  }

  static void put(String key, dynamic value) {
    _box?.put(key, value);
  }

  static dynamic get(String key) {
    return _box?.get(key);
  }

  static void delete(String key) {
    _box?.delete(key);
  }

  static void clear() {
    _box?.clear();
  }

  static bool containsKey(String key) {
    return _box?.containsKey(key) ?? false;
  }

  // Cache methods
  static void cacheData(String key, dynamic data) {
    _box?.put('cache_$key', {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static dynamic getCachedData(String key, {int maxAgeMinutes = 60}) {
    final cached = _box?.get('cache_$key');
    if (cached == null) return null;

    final timestamp = cached['timestamp'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;

    if (age > maxAgeMinutes * 60 * 1000) {
      _box?.delete('cache_$key');
      return null;
    }

    return cached['data'];
  }
}
