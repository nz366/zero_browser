import 'dart:convert';

import 'package:zero_browser/client/client.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:zero_browser/model/data.dart';
import 'package:zero_browser/model/sites.dart';
import 'package:zero_browser/utils/utils.dart';

class HackernewsSite implements SiteProfile {
  @override
  List<String> get domains => ["news.ycombinator.com"];
  static const firebaseAPI = "https://hacker-news.firebaseio.com/v0";
  static const websiteHost = "https://news.ycombinator.com";
  @override
  RequestProfile get request => RequestProfile(
    getContent: (Client client, String path) async {
      final uriStr = path;
      if (uriStr.contains('/item?id=')) {
        final id = uriStr.split('=').last;
        final itemResponse = await client.httpRequest(
          '$firebaseAPI/item/$id.json',
          throwError: true,
        );

        final item = jsonDecode(itemResponse.body);
        if (item != null && item['type'] == 'story') {
          final comments = await fetchcomments(
            client,
            item['kids'] ?? [],
            null,
          );
          String markdown = "# ${item['title'] ?? 'No Title'}\n\n";
          if (item['url'] != null) {
            markdown += "Source: (${item['url']})\n\n";
          }
          if (item['text'] != null) {
            markdown += html2md.convert(item['text']);
          }

          return Structure(
            body: [MarkdownSection(markdown), CommentThreadSection(comments)],
            statusCode: 200,
            title: item['title'] ?? 'Hacker News',
          );
        }
      }

      final topStoriesResponse = await client.httpRequest(
        '$firebaseAPI/topstories.json',
        throwError: false,
      );

      final List<dynamic> storyIds = jsonDecode(topStoriesResponse.body);
      final limitedIds = storyIds.take(30).toList();

      final List<Article> posts = [];

      final storyFutures = limitedIds.map(
        (id) => client.httpRequest('$firebaseAPI/item/$id.json'),
      );

      final storyResponses = await Future.wait(storyFutures);

      for (var response in storyResponses) {
        if (response.statusCode == 200) {
          final item = jsonDecode(response.body);
          if (item != null && item['type'] == 'story') {
            posts.add(
              Article(
                title: item['title'] ?? 'No Title',
                content: item['url'] != null
                    ? "Source: (${item['url']})\n\n${item['text'] != null ? html2md.convert(item['text']) : ''}"
                    : (item['text'] != null
                          ? html2md.convert(item['text'])
                          : ''),
                author: item['by'] ?? 'unknown',
                time: DateTime.fromMillisecondsSinceEpoch(
                  (item['time'] ?? 0) * 1000,
                ).toString(),
                upvotes: item['score'] ?? 0,
                subgroup: 'hacker-news',
                url: '$websiteHost/item?id=${item['id']}',
                thumbnail: item['thumbnail'] ?? '',
              ),
            );
          }
        }
      }

      return Structure(
        body: [
          ArticleListSection(
            title: "Hacker News",
            layout: LayoutConfig.list,
            articles: posts,
          ),
        ],
        statusCode: 200,
        title: "Hacker News",
      );
    },
  );

  Future<List<CommentData>> fetchcomments(
    Client client,
    List<dynamic> items,
    TimeOut? timeout,
  ) async {
    var futures = <Future<CommentData>>[];

    for (var element in items) {
      futures.add(
        Future.microtask(() async {
          if (timeout != null && timeout.isExpired) {
            return CommentData(
              id: element,
              author: "[System]",
              content: "Error: Timeout",
              createdAt: DateTime.now(),
              replies: [],
            );
          }
          final commentResponse = await client.httpRequest(
            '$firebaseAPI/item/$element.json',
          );

          if (commentResponse.statusCode != 200) {
            return CommentData(
              id: element,
              author: "[System]",
              content: "Error: ${commentResponse.statusCode}",
              createdAt: DateTime.now(),
              replies: [],
            );
          }

          final comment = jsonDecode(commentResponse.body);

          final kidslist = comment['kids'] ?? [];

          final replies = await fetchcomments(client, kidslist, timeout);

          if (comment != null && comment['type'] == 'comment') {
            final htmlmd = html2md
                .convert(comment['text'] ?? "")
                .replaceAll(r'\', '');

            return CommentData(
              content: htmlmd,
              author: comment['by'] ?? 'unknown',
              id: element.toString(),
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                (comment['time'] ?? 0) * 1000,
              ),
              replies: replies,
            );
          }

          return CommentData(
            id: element,
            author: "[System]",
            content: "Error: Invalid Comment",
            createdAt: DateTime.now(),
            replies: [],
          );
        }),
      );
    }

    return Future.wait(futures);
  }
}
