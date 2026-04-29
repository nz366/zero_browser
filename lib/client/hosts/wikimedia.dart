import 'package:html/parser.dart' as html_parser;
import 'package:html2md/html2md.dart' as html2md;
import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

class Mediawiki extends RequestTransformer {
  Mediawiki({Uri? uri})
    : super(host: ['en.wikipedia.org', 'wikimedia.org'], uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => Mediawiki(uri: uri);

  @override
  Future<DataResponse> getData() async {
    http.Response resp = await http.get(uri);

    final body = resp.body;

    // Use the html package to resolve relative URLs in the DOM before converting to Markdown
    final dom = html_parser.parse(body);
    final hostpageuri = uri;

    for (var element in dom.querySelectorAll('a, img')) {
      final attr = element.localName == 'a' ? 'href' : 'src';
      final value = element.attributes[attr];
      if (value != null) {
        final valUri = Uri.parse(value);
        if (valUri.host.isEmpty) {
          element.attributes[attr] = hostpageuri.resolve(value).toString();
        }
      }
    }

    final mdText = html2md.convert(dom.body?.innerHtml ?? body);

    return DataResponse(
      body: [MarkdownSection(mdText)],
      statusCode: resp.statusCode,
      title: "Wikipedia",
    );
  }
}
