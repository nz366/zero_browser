import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:zero_browser/model/data.dart';

class HackernewsRequest extends RequestTransformer {
  HackernewsRequest({Uri? uri})
    : super(host: ["news.ycombinator.com"], uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => HackernewsRequest(uri: uri);

  static const firebaseAPI = "https://hacker-news.firebaseio.com/v0";
  static const websiteHost = "https://news.ycombinator.com";
  @override
  Future<DataResponse> getData() async {
    final uriStr = uri.toString();
    if (uriStr.contains('/item?id=')) {
      final id = uriStr.split('=').last;
      final itemResponse = await http.get(
        Uri.parse('$firebaseAPI/item/$id.json'),
      );
      if (itemResponse.statusCode != 200) {
        return DataResponse.fromHttpResponse(itemResponse, "HackerNews Error");
      }

      final item = jsonDecode(itemResponse.body);
      if (item != null && item['type'] == 'story') {
        final comments = await fetchcomments(item['kids'] ?? []);
        String markdown = "# ${item['title'] ?? 'No Title'}\n\n";
        if (item['url'] != null) {
          markdown += "Source: (${item['url']})\n\n";
        }
        if (item['text'] != null) {
          markdown += html2md.convert(item['text']);
        }

        return DataResponse(
          body: [MarkdownSection(markdown), CommentThreadSection(comments)],
          statusCode: 200,
          title: item['title'] ?? 'Hacker News',
        );
      }
    }

    // For now, we only support the main page (top stories)
    // In a full implementation, we'd handle different HackerNews URLs
    final topStoriesResponse = await http.get(
      Uri.parse('https://hacker-news.firebaseio.com/v0/topstories.json'),
    );

    if (topStoriesResponse.statusCode != 200) {
      return DataResponse.fromHttpResponse(
        topStoriesResponse,
        "HackerNews Error",
      );
    }

    final List<dynamic> storyIds = jsonDecode(topStoriesResponse.body);
    // Limit to top 30 stories for performance
    final limitedIds = storyIds.take(30).toList();

    final List<Article> posts = [];

    // Fetch details for each story in parallel
    final storyFutures = limitedIds.map(
      (id) => http.get(
        Uri.parse('https://hacker-news.firebaseio.com/v0/item/$id.json'),
      ),
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
                  : (item['text'] != null ? html2md.convert(item['text']) : ''),
              author: item['by'] ?? 'unknown',
              time: DateTime.fromMillisecondsSinceEpoch(
                (item['time'] ?? 0) * 1000,
              ).toString(),
              upvotes: item['score'] ?? 0,
              subgroup: 'hacker-news',
              url: 'https://news.ycombinator.com/item?id=${item['id']}',
              thumbnail: item['thumbnail'] ?? '',
            ),
          );
        }
      }
    }

    return DataResponse(
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
  }

  Future<List<CommentData>> fetchcomments(List<dynamic> items) async {
    final comments = <CommentData>[];

    for (var element in items) {
      final commentResponse = await http.get(
        Uri.parse('$firebaseAPI/item/$element.json'),
      );
      if (commentResponse.statusCode != 200) {
        continue;
      }

      final comment = jsonDecode(commentResponse.body);

      final kidslist = comment['kids'] ?? [];

      final replies = await fetchcomments(kidslist);

      if (comment != null && comment['type'] == 'comment') {
        final htmlmd = html2md
            .convert(comment['text'] ?? "")
            .replaceAll(r'\', '');

        comments.add(
          CommentData(
            content: htmlmd,

            author: comment['by'] ?? 'unknown',

            id: element.toString(),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (comment['time'] ?? 0) * 1000,
            ),
            score: comment['score'] ?? 0,
            replies: replies,
          ),
        );
      }
    }
    return comments;
  }
}
