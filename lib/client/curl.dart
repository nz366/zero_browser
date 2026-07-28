import 'dart:io';
import 'package:http/http.dart' as http;

Future<http.Response> getData(String path) async {
  final result = await Process.run('curl', ['-L', path]);
  final data = http.Response(
    result.stdout.toString(),
    result.exitCode == 0 ? 200 : 500,
    reasonPhrase: result.exitCode == 0 ? null : result.stderr.toString(),
  );
  if (data.statusCode != 200) {
    throw Exception(data.reasonPhrase);
  }
  return data;
}
