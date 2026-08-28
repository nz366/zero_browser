export 'registry.dart';
import 'dart:io' show File, HttpHeaders;

import 'package:http/http.dart';
import 'package:mime/mime.dart';
import 'package:zero_browser/client/http_cache.dart';
import 'package:zero_browser/utils/utils.dart';

class ResponseDetails extends Response {
  final Uri uri;
  final String? title;

  ResponseDetails.fromGetRequest(
    Response response, {
    required this.uri,
    this.title,
  }) : super(
         response.body,
         response.statusCode,
         headers: response.headers,
         request: response.request,
         isRedirect: response.isRedirect,
         persistentConnection: response.persistentConnection,
         reasonPhrase: response.reasonPhrase,
       );

  String get defaultTitle => title ?? uri.host;

  ResponseDetails copyWith({String? title}) {
    return ResponseDetails.fromGetRequest(this, uri: uri, title: title);
  }
}

class Client {
  final ClientCache cache = ClientCache();

  Future<ResponseDetails> httpRequest(
    String url, {
    bool throwError = false,
  }) async {
    return await httpUriRequest(Uri.parse(url), throwError: throwError);
  }

  Future<ResponseDetails> httpUriRequest(
    Uri url, {
    bool throwError = false,
  }) async {
    final response = await cache.getOrFetch(url, ([headers]) async {
      final fixedUri = url.insertOrIgnore(newScheme: "https://");
      return await get(fixedUri, headers: headers);
    });

    if (throwError && response.statusCode != 200) {
      throw Exception(
        "Failed with unexceptable status code: ${response.statusCode}",
      );
    }

    return ResponseDetails.fromGetRequest(response, uri: url);
  }

  Future<ResponseDetails> markdownRequest(String url) async {
    final uri = Uri.parse(url);
    final response = await get(uri, headers: {'Accept': 'text/markdown'});
    return ResponseDetails.fromGetRequest(response, uri: uri);
  }

  Future<ResponseDetails> localRequest(String path) async {
    final file = File(path);

    if (await file.exists()) {
      try {
        final mimeTypeString =
            lookupMimeType(path) ?? 'application/octet-stream';

        final headers = {HttpHeaders.contentTypeHeader: mimeTypeString};

        final bytes = await file.readAsBytes();

        return ResponseDetails.fromGetRequest(
          Response.bytes(bytes, 200, headers: headers),
          uri: Uri.parse(path),
        );
      } catch (e) {
        return ResponseDetails.fromGetRequest(
          Response("File read error $e", 500),
          uri: Uri.parse(path),
        );
      }
    } else {
      return ResponseDetails.fromGetRequest(
        Response("File doesn't exist", 404),
        uri: Uri.parse(path),
      );
    }
  }
}
