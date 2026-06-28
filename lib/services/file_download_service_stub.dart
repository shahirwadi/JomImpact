import 'dart:typed_data';

Future<String> saveDownloadedFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) {
  throw UnsupportedError('File downloads are not supported on this platform.');
}
