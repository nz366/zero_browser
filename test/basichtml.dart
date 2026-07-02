import 'dart:io';

import 'package:zero_browser/client/hosts/basichtml.dart';

main() async {
  final src = await File("test/test.html").readAsString();

  final data = cleanHtmlSource(src);

  final result = data.body?.innerHtml;
  File("reslut.txt").writeAsString(result!);
  assert(result.contains(".mw-parser") != true);
}
