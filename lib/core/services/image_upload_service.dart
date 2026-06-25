import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImageUploadService {
  // TODO: Replace with actual ImgBB API key provided by the user
  static const String _imgbbApiKey = 'YOUR_IMGBB_API_KEY';
  static const String _imgbbEndpoint = 'https://api.imgbb.com/1/upload';

  static Future<String?> uploadImage(String localPath) async {
    try {
      String base64Image;

      if (kIsWeb) {
        // For web, you might have to handle bytes directly if localPath is a blob URL.
        // If it's a blob URL, we would need to fetch it first.
        // Assuming we have the bytes, but for simplicity we will just do this:
        final response = await http.get(Uri.parse(localPath));
        base64Image = base64Encode(response.bodyBytes);
      } else {
        final file = File(localPath);
        if (!await file.exists()) return null;
        final bytes = await file.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      final uri = Uri.parse('$_imgbbEndpoint?key=$_imgbbApiKey');
      final response = await http.post(
        uri,
        body: {
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data']['url'] as String;
      } else {
        print('ImgBB Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }
}
