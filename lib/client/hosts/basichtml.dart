import 'package:html2md/html2md.dart' as html2md;
import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

DataResponse useful_html_content(http.Response response) {
  final string = response.body;
  // Most websites follows common structure for SEO optimization.
  final title = RegExp(
    r'<meta property="og:title" content="(.*?)">',
  ).allMatches(string).map((e) => e.group(1)).join('');

  // <body id="www-wikipedia-org" class=" jsl10n-visible">

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
    title: title.isEmpty ? "No Title" : title,
  );
}
