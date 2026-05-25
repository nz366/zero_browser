import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

class BlueBirdRequest extends RequestTransformer {
  BlueBirdRequest({Uri? uri})
    : super(host: ["xcancel.com", "twitter.com", "x.com"], uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => BlueBirdRequest(uri: uri);

  @override
  Future<DataResponse> getData() async {
    final uri = replace_with_fallback(host.first, super.uri);

    final response = await http.get(uri);

    //profile div.tweet-body>
    //
    //content
    // body> div.container> main-thread > tweet-content
    final document = parse(response.body);

    final post = read_post(document);

    final replies = read_replies(document);

    return DataResponse(
      title: "Bluebird: $uri",
      body: [...post, CommentThreadSection(replies)],
      statusCode: 200,
      sourceUri: uri,
    );
  }
}

List<Section> read_post(Document document) {
  final el = document.querySelector("main-thread>main-tweet");

  return [MarkdownSection(html2md.convert(el.toString()))];
}

List<CommentData> read_replies(Document document) {
  final query = document.querySelectorAll("div.timeline-item");

  return query.map((e) {
    return CommentData(
      content: html2md.convert(
        e.querySelector("div.tweet-content")?.innerHtml ?? "",
      ),
      author: e.querySelector("div.fullname-and-username")?.text.trim() ?? "",
      replies: [],
      id:
          e
              .querySelector("a.tweet-link")
              ?.attributes["href"]
              ?.split("/")
              .last ??
          "",
      createdAt: DateTime.tryParse(
        e.querySelector("span.tweet-date a")?.attributes["title"] ?? "",
      ),
    );
  }).toList();
}

Uri replace_with_fallback(String host, Uri uri) {
  return Uri.https(host, uri.path);
}
