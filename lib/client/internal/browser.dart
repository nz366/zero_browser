import 'package:drift/drift.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/client/internal/demo.dart';
import 'package:zero_browser/database/database.dart';
import 'package:zero_browser/model/model.dart';
import 'package:zero_browser/utils/utils.dart';

class BrowserPageProfile implements RequestProfile {
  @override
  RequestProfile copyWith({getContent}) {
    return this;
  }

  @override
  Future<Structure> Function(Client client, String path) get getContent =>
      getContentstatic;
  static const String _newTabMarkdown = '''
# Testing Sites
- [Wikipedia](https://en.wikipedia.org)
- [Hacker News](https://news.ycombinator.com)
- [Reddit](https://www.reddit.com)
- [Imgur](https://imgur.com)
- [Instagram](https://www.instagram.com)
- [Github](https://github.com)
- [Codeberg](https://codeberg.org)
- [Cloudflare Blogs](https://blog.cloudflare.com)


# Other
- [Demo](browser://demo)

''';

  Future<Structure> getContentstatic(Client client, String path) async {
    final uri = Uri.parse(path);
    switch (uri.authority) {
      case "newtab":
        return Structure(
          body: [MarkdownSection(_newTabMarkdown)],
          statusCode: 200,
          title: "New Tab",
        );
      case 'demo':
        return Structure(body: demopage(), statusCode: 200, title: "Demo");
      case "settings":
        return Structure(
          body: [
            MarkdownSection("Settings....  (WIP)"),
            FormSection(
              fields: {
                "Theme": DropdownField(
                  name: "theme",
                  options: ["Dark", "Light", "System"],
                ),
                "Language": DropdownField(
                  name: "language",
                  options: ["English"],
                ),
              },
            ),
          ],
          statusCode: 200,
          title: "Settings",
        );
      case "bookmarks":
        final bookmarksList = await appDatabase
            .select(appDatabase.bookmarks)
            .get();

        final columns = ["Title", "Url", "Time"];
        final List<List<String>> rows = [
          for (final item in bookmarksList)
            [item.title ?? "", item.url, item.createdAt.toIso8601String()],
        ];

        return Structure(
          body: [
            MarkdownSection("# Bookmarks"),
            TableSection(columns: columns, rows: rows),
          ],
          statusCode: 200,
          title: "Bookmarks",
        );
      case "history":
        final visited = appDatabase.alias(appDatabase.urls, 'visited');

        final query =
            appDatabase.select(appDatabase.history).join([
              innerJoin(
                visited,
                visited.id.equalsExp(appDatabase.history.urlId),
              ),
            ])..orderBy([
              OrderingTerm(
                expression: appDatabase.history.createdAt,
                mode: OrderingMode.desc,
              ),
            ]);

        final rows = await query.get();

        final columns = ["Title", "Url", "Time"];

        final List<List<String>> items = [
          for (final row in rows)
            [
              row.readTable(visited).title ?? row.readTable(visited).url,
              row.readTable(visited).url,
              row
                  .readTable(appDatabase.history)
                  .createdAt
                  .toRelativeTime(DateTime.now()),
            ],
        ];

        return Structure(
          body: [
            MarkdownSection("# History"),
            TableSection(columns: columns, rows: items),
          ],
          statusCode: 200,
          title: "History",
        );
      default:
        return Structure(
          body: [MarkdownSection("Not Found \n ${uri.toString()}")],
          statusCode: 500,
          title: "Not Found",
        );
    }
  }
}
