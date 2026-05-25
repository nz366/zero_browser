import 'package:http/http.dart' as http;
import 'package:zero_browser/client/hosts/basichtml.dart';
import 'dart:io';

import 'package:zero_browser/model/data.dart';

void main() async {
  final htmlfile = await File("test/test.html").readAsString();
  final useful = usefulHtmlContent(
    http.Response(
      htmlfile,
      200,
      headers: {"content-type": "text/html; charset=utf-8"},
    ),
    "test",
  );

  assert(useful.body.length == 2);

  assert((useful.body.last as MarkdownSection).data.isNotEmpty);
}
