import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionUtils {
  static final _storage = const FlutterSecureStorage();
  static final _keyLabel = 'lovesync_encryption_key';
  static String? _inMemoryKey;

  static Future<encrypt.Key> _getKey() async {
    if (kIsWeb) {
      // On web, flutter_secure_storage uses web localStorage
      // but we also keep an in-memory fallback
      if (_inMemoryKey != null) {
        return encrypt.Key.fromBase64(_inMemoryKey!);
      }
      try {
        String? keyString = await _storage.read(key: _keyLabel);
        if (keyString == null) {
          final key = encrypt.Key.fromSecureRandom(32);
          keyString = key.base64;
          await _storage.write(key: _keyLabel, value: keyString);
        }
        _inMemoryKey = keyString;
        return encrypt.Key.fromBase64(keyString);
      } catch (e) {
        // Fallback to in-memory only if web storage fails
        if (_inMemoryKey != null) {
          return encrypt.Key.fromBase64(_inMemoryKey!);
        }
        final key = encrypt.Key.fromSecureRandom(32);
        _inMemoryKey = key.base64;
        return key;
      }
    }

    String? keyString = await _storage.read(key: _keyLabel);
    if (keyString == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      keyString = key.base64;
      await _storage.write(key: _keyLabel, value: keyString);
    }
    return encrypt.Key.fromBase64(keyString);
  }

  static Future<String> encryptText(String text) async {
    final key = await _getKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(text, iv: iv);
    final combined = base64.encode(iv.bytes + encrypted.bytes);
    return combined;
  }

  static Future<String> decryptText(String encryptedText) async {
    try {
      final key = await _getKey();
      final combined = base64.decode(encryptedText);
      final iv = encrypt.IV(combined.sublist(0, 16));
      final encryptedBytes = combined.sublist(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: iv);
      return utf8.decode(decrypted);
    } catch (e) {
      return encryptedText;
    }
  }

  static String generateInviteCode() {
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static String generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(28, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
