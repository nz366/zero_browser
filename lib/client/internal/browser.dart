import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/client/internal/demo.dart';
import 'package:zero_browser/database/database.dart';
import 'package:zero_browser/model/data.dart';

class BrowserRequest extends RequestTransformer {
  static const String _newTabMarkdown = '''
# Testing Sites
- [Wikipedia](https://en.wikipedia.org)
- [Hacker News](https://news.ycombinator.com)
- [Reddit](https://www.reddit.com)
- [Imgur](https://imgur.com)
- [Instagram](https://www.instagram.com)
- [Github](https://github.com)
- [Codeberg](https://codeberg.org)
- [Cloudflare Blogs](https://blog.cloudflare.com/markdown-for-agents/)


# Other
- [Demo](browser:demo)

''';

  static const String _settingsMarkdown = '''
# Settings

''';

  @override
  BrowserRequest({Uri? uri})
    : super(uri: uri ?? Uri.parse("browser:newtab"), host: ["*"]);

  @override
  RequestTransformer withUri(Uri uri) => BrowserRequest(uri: uri);

  // @override
  // Future<http.Response> djdsjs() async {
  //   return http.Response("", 200);
  // }

  @override
  Future<DataResponse> getData() async {
    switch (uri.path) {
      case "newtab":
        return DataResponse(
          body: [MarkdownSection(_newTabMarkdown)],
          statusCode: 200,
          title: "New Tab",
        );
      case 'demo':
        return DataResponse(body: demopage, statusCode: 200, title: "Settings");
      case "settings":
        return DataResponse(
          body: [MarkdownSection(_settingsMarkdown)],
          statusCode: 200,
          title: "Settings",
        );
      case "bookmarks":
        final bookmarksList = await appDatabase
            .select(appDatabase.bookmarks)
            .get();
        final items = bookmarksList
            .map(
              (b) => {
                "title": b.title ?? b.url,
                "url": b.url,
                "time": b.createdAt.toIso8601String(),
              },
            )
            .toList();

        return DataResponse(
          body: [TableSection(items: items)],
          statusCode: 200,
          title: "Bookmarks",
        );

      default:
        return DataResponse(
          body: [MarkdownSection("Not Found \n ${uri.toString()}")],
          statusCode: 500,
          title: "Not Found",
        );
    }
  }
}
