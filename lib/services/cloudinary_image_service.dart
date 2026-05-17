import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/app_env.dart';

class CloudinaryImageService {
  Future<String> uploadImage({
    required XFile file,
    required String folder,
  }) async {
    if (!AppEnv.isCloudinaryConfigured) {
      throw Exception(
        'Cloudinary is not configured. Start the app with scripts/run_dev.ps1 or flutter run --dart-define-from-file=env/dev.json, or pass CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET with --dart-define.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppEnv.cloudinaryCloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppEnv.cloudinaryUploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['error']?['message'] ?? 'Image upload failed.');
    }

    final secureUrl = body['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary did not return an image URL.');
    }

    return secureUrl;
  }
}
