import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/app_env.dart';

class CloudinaryImageService {
  Future<String> uploadImage({
    required XFile file,
    required String folder,
  }) async {
    final config = await _loadConfig();

    if (!config.isConfigured) {
      throw Exception(
        'Cloudinary is not configured. Add CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET to env/dev.json, then fully restart the app.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${config.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = config.uploadPreset
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

  Future<_CloudinaryConfig> _loadConfig() async {
    if (AppEnv.isCloudinaryConfigured) {
      return const _CloudinaryConfig(
        cloudName: AppEnv.cloudinaryCloudName,
        uploadPreset: AppEnv.cloudinaryUploadPreset,
      );
    }

    try {
      final raw = await rootBundle.loadString('env/dev.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return _CloudinaryConfig(
        cloudName: (json['CLOUDINARY_CLOUD_NAME'] as String?)?.trim() ?? '',
        uploadPreset:
            (json['CLOUDINARY_UPLOAD_PRESET'] as String?)?.trim() ?? '',
      );
    } catch (_) {
      return const _CloudinaryConfig(cloudName: '', uploadPreset: '');
    }
  }
}

class _CloudinaryConfig {
  final String cloudName;
  final String uploadPreset;

  const _CloudinaryConfig({
    required this.cloudName,
    required this.uploadPreset,
  });

  bool get isConfigured => cloudName.isNotEmpty && uploadPreset.isNotEmpty;
}
