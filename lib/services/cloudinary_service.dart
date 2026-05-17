// lib/services/cloudinary_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../constants/app_constants.dart';

class CloudinaryService {
  /// Upload a [File] to Cloudinary, returns the secure URL.
  static Future<String> uploadFile(File file, {String folder = 'garage'}) async {
    final uri = Uri.parse(CloudinaryConfig.baseUrl);
    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    request.fields['folder'] = folder;

    final ext = file.path.split('.').last.toLowerCase();
    final mimeType = _mimeType(ext);

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType.parse(mimeType),
    ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String;
    } else {
      throw Exception('Cloudinary upload failed: $body');
    }
  }

  /// Upload raw bytes (e.g. signature PNG) to Cloudinary, returns secure URL.
  static Future<String> uploadBytes(
    Uint8List bytes, {
    String folder = 'garage/signatures',
    String fileName = 'signature',
  }) async {
    final uri = Uri.parse(CloudinaryConfig.baseUrl);
    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    request.fields['folder'] = folder;

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: '$fileName.png',
      contentType: MediaType('image', 'png'),
    ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String;
    } else {
      throw Exception('Cloudinary signature upload failed: $body');
    }
  }

  static String _mimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
