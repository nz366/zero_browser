import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/client/hosts/basichtml.dart';
import 'package:zero_browser/model/model.dart';

class BlueBirdSite implements SiteProfile {
  @override
  List<String> get domains => ["xcancel.com", "twitter.com", "x.com"];

  @override
  RequestProfile get request => RequestProfile(
    getContent: (Client client, String path) async {
      final uri = Uri.parse(path).replace(host: domains.first);

      final response = await client.httpUriRequest(uri, throwError: false);
      final document = parse(response.body);
      final title = htmlDocumentTitle(document);

      final replies = read_replies(document);

      return Structure(
        title: title ?? uri.toString(),
        body: [CommentThreadSection(replies)],
        statusCode: 200,
      );
    },
  );
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
      author: (e.querySelector("div.fullname-and-username")?.text.trim() ?? "")
          .replaceAll("\n", "")
          .replaceAll(" ", ""),
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
