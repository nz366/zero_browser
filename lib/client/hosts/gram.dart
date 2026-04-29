import 'dart:convert';

import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

class GramRequest extends RequestTransformer {
  GramRequest({Uri? uri})
    : super(
        host: ['kittygr.am', 'instagram.com', 'www.instagram.com'],
        uri: uri ?? Uri(),
      );

  @override
  RequestTransformer withUri(Uri uri) => GramRequest(uri: uri);

  @override
  Future<DataResponse> getData() async {
    if (uri.queryParameters.containsKey("form_data")) {
      final formData = json.decode(uri.queryParameters['form_data']!);
      final search = formData['fields']['search']['data'];

      if (search == null) {
        return DataResponse(
          body: [
            MarkdownSection(
              "Invalid Form Data  \n```${json.encode(formData)} ```",
            ),
          ],
          statusCode: 400,
          title: "Instagram",
        );
      }

      final resp = await http.get(Uri.parse("https://kittygr.am/$search"));

      final body = resp.body;

      final pr = html.parse(body);

      final List<Article> images = pr
          .querySelectorAll('img')
          .where((e) => e.attributes.containsKey('src'))
          .map(
            (e) => Article(
              title: e.attributes['alt'] ?? "",
              content: e.attributes['alt'] ?? "",
              subgroup: "",
              author: "",
              time: "",
              upvotes: 0,
              url: e.attributes['src']!,
              thumbnail: e.attributes['src']!,
            ),
          )
          .toList();

      return DataResponse(
        body: [
          ArticleListSection(
            title: "title",
            layout: LayoutConfig.masonry,
            articles: images,
          ),
        ],
        statusCode: resp.statusCode,
        title: "${search} Instagram",
      );
    } else {
      return DataResponse(
        body: [
          FormSection(
            title: 'search',
            fields: {'search': TextField(name: 'search', hint: 'Search')},
          ),
        ],
        statusCode: 200,
        title: "Instagram",
      );
    }
  }
}

class GurRequest extends RequestTransformer {
  GurRequest({Uri? uri})
    : super(host: ['rmgur.com', 'imgur.com'], uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => GurRequest(uri: uri);

  @override
  Future<DataResponse> getData() async {
    final homepage = 'trending';

    return buildrmgur(homepage);
  }
}

Future<DataResponse> buildrmgur(String homepage) async {
  final resp = await http.get(Uri.parse("https://rmgur.com/$homepage"));

  return DataResponse(
    body: [MarkdownSection(resp.body)],
    statusCode: resp.statusCode,
    title: "Rmgur",
  );
}
