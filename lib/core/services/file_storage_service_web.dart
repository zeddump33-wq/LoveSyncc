import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class FileStorageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndSaveImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null) return null;

      final Uint8List bytes = await image.readAsBytes();
      final mimeType = image.mimeType ?? 'image/jpeg';
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    } catch (_) {
      return null;
    }
  }

  static Future<String?> pickAndSaveVoice() async => null;

  static Future<void> deleteFile(String path) async {}

  static Future<String> getAppDirectory() async => 'lovesync';
}
