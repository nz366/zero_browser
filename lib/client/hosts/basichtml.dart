import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html2md/html2md.dart' as html2md;
import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

String? htmlDocumentTitle(Document document) {
  return document.querySelector("title")?.text ??
      document.querySelector("meta[property='og:title']")?.text;
}

DataResponse usefulHtmlContent(http.Response response, String? fallbackTitle) {
  final string = response.body;
  final document = parse(string);
  final title = htmlDocumentTitle(document);

  var mainContent = string.split("<body").last.split("</body>").first;

  final firstindex = mainContent.indexOf(">");

  mainContent = mainContent.substring(firstindex + 1, mainContent.length);

  // final main_content = RegExp(
  //   r'<body[^>]*>(.*?)</body>',
  //   multiLine: true,
  // ).allMatches(string).map((e) => e.group(1)).join('');
  var mdText = html2md.convert(mainContent);

  return DataResponse(
    body: [MarkdownSection(mdText)],
    statusCode: response.statusCode,
    title: title ?? fallbackTitle ?? "No Title",
  );
}

Document cleanHtmlSource(String body) {
  Document dom = html_parser.parse(body);
  dom.querySelectorAll('style').forEach((element) => element.remove());
  return dom;
}

List<Section> documentToSections(Document dom) {
  final mainContent = (dom.body?.querySelector("#bodyContent")?.innerHtml);

  var mdText = html2md.convert(mainContent!);

  return [MarkdownSection(mdText)];
}
