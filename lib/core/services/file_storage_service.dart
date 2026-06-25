import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
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

      if (kIsWeb) {
        return image.path;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/lovesync/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${imagesDir.path}/$fileName';
      await File(image.path).copy(savedPath);
      return savedPath;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> pickAndSaveVoice() async {
    if (kIsWeb) return null;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final voiceDir = Directory('${appDir.path}/lovesync/voice');
      if (!await voiceDir.exists()) {
        await voiceDir.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      return '${voiceDir.path}/$fileName';
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteFile(String path) async {
    if (kIsWeb) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
    }
  }

  static Future<String> getAppDirectory() async {
    if (kIsWeb) return 'lovesync';
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/lovesync';
  }
}
