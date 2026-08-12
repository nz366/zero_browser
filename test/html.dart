import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/client/hosts/basichtml.dart';
import 'dart:io';

import 'package:zero_browser/model/data.dart';

class Testclient implements Client {
  @override
  Uri? baseUri;

  @override
  Future<http.Response> httpRequest(String url, {throwError = false}) async {
    final htmlfile = await File("test/test.html").readAsString();
    return http.Response(
      htmlfile,
      200,
      headers: {"content-type": "text/html; charset=utf-8"},
    );
  }

  @override
  Future<http.Response> httpUriRequest(Uri url, {throwError = false}) {
    // TODO: implement httpUriRequest
    throw UnimplementedError();
  }

  @override
  Future<http.Response> localRequest(String path) {
    // TODO: implement localRequest
    throw UnimplementedError();
  }

  @override
  Future<http.Response> markdownRequest(String url) {
    // TODO: implement markdownRequest
    throw UnimplementedError();
  }
}

void main() async {
  final client = Testclient();

  final useful = await HtmlProfile.getContentstatic(client, "test");

  assert(useful.body.length == 2);

  assert((useful.body.last as MarkdownSection).data.isNotEmpty);
}
