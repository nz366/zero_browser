export 'registry.dart';
import 'dart:io' show File, HttpHeaders;

import 'package:http/http.dart';
import 'package:mime/mime.dart';
import 'package:zero_browser/utils/utils.dart';

class Client {
  Future<Response> httpRequest(String url, {throwError = false}) async {
    return await httpUriRequest(Uri.parse(url), throwError: throwError);
  }

  Future<Response> httpUriRequest(Uri url, {throwError = false}) async {
    final response = await get(url.insertOrIgnore(sceheme: "https://"));

    if (throwError && response.statusCode != 200) {
      throw Exception(
        "Failed with unexceptable status code: ${response.statusCode}",
      );
    }

    return response;
  }

  Future<Response> markdownRequest(String url) async {
    return await get(Uri.parse(url), headers: {'Accept': 'text/markdown'});
  }

  Future<Response> localRequest(String path) async {
    final file = File(path);

    if (await file.exists()) {
      try {
        final mimeTypeString =
            lookupMimeType(path) ?? 'application/octet-stream';

        final headers = {HttpHeaders.contentTypeHeader: mimeTypeString};

        final bytes = await file.readAsBytes();

        return Response.bytes(bytes, 200, headers: headers);
      } catch (e) {
        return Response("File read error $e", 500);
      }
    } else {
      return Response("File doesn't exist", 404);
    }
  }
}
