import 'dart:io';
import 'dart:typed_data';

Future<String> saveDownloadedFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final directory = await _downloadDirectory();
  if (!await directory.exists()) await directory.create(recursive: true);
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<Directory> _downloadDirectory() async {
  final home = Platform.isWindows
      ? Platform.environment['USERPROFILE']
      : Platform.environment['HOME'];
  if (home != null && home.isNotEmpty) {
    if (Platform.isIOS) return Directory('$home/Documents');
    return Directory('$home${Platform.pathSeparator}Downloads');
  }
  if (Platform.isAndroid) {
    final downloads = Directory('/storage/emulated/0/Download');
    if (await downloads.exists()) return downloads;
  }
  return Directory.systemTemp;
}
