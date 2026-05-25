import 'dart:io';

import 'package:zero_browser/client/hosts/bluebird.dart';
import 'package:html/parser.dart' as html_parser;

main() {
  final html = File("test/test-blue.html").readAsStringSync();
  final document = html_parser.parse(html);
  final replies = read_replies(document);

  assert(replies.isNotEmpty);
}
