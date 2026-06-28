import 'dart:typed_data';

import 'file_download_service_stub.dart'
    if (dart.library.html) 'file_download_service_web.dart'
    if (dart.library.io) 'file_download_service_io.dart' as platform;

Future<String> saveDownloadedFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) =>
    platform.saveDownloadedFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
