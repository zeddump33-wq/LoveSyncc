import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageUploadService {
  static const String _imgbbApiKey = 'YOUR_IMGBB_API_KEY';
  static const String _imgbbEndpoint = 'https://api.imgbb.com/1/upload';

  static Future<String?> uploadImage(String localPath) async {
    try {
      if (_imgbbApiKey == 'YOUR_IMGBB_API_KEY') {
        return localPath;
      }

      String base64Image;

      if (kIsWeb || localPath.startsWith('data:')) {
        final commaIndex = localPath.indexOf(',');
        if (commaIndex == -1) return localPath;
        base64Image = localPath.substring(commaIndex + 1);
      } else {
        final file = File(localPath);
        if (!await file.exists()) return localPath;
        final bytes = await file.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      final uri = Uri.parse('$_imgbbEndpoint?key=$_imgbbApiKey');
      final response = await http.post(
        uri,
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data']['url'] as String?;
      }
      return localPath;
    } catch (e) {
      print('Image upload error: $e');
      return localPath;
    }
  }
}
