import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> savePdfReport(Uint8List bytes, String filename) async {
  final downloadsDirectory = await getDownloadsDirectory();
  final directory = downloadsDirectory ?? await getApplicationDocumentsDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
