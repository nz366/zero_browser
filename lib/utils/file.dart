import 'dart:io';
import 'dart:math';

String formatFileSize(int bytes) {
  if (bytes <= 0) return "0 B";

  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  final i = (log(bytes) / log(1024)).floor();

  return "${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
}

String? fileName(String? path) {
  if (path == null || path.isEmpty) return null;

  return path.split(Platform.pathSeparator).last;
}
