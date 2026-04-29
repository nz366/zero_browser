import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as html;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';
import 'package:html2md/html2md.dart' as html2md;

class RedlibRequest extends RequestTransformer {
  RedlibRequest({Uri? uri})
    : super(
        host: ['eu.safereddit.com', 'www.reddit.com', "reddit.com"],
        uri: uri ?? Uri(),
      );

  List<String> get fallbacks => super.host.take(1).toList();

  @override
  RequestTransformer withUri(Uri uri) => RedlibRequest(uri: uri);

  @override
  Future<DataResponse> getData() async {
    http.Response? data;

    for (var host in fallbacks) {
      final fallbackuri = Uri.parse("https://" + host + uri.path);

      final fallbackresp = await http.get(fallbackuri);

      if (fallbackresp.statusCode == 200) {
        data = fallbackresp;
        break;
      }
    }

    if (data == null) {
      final data = await http.get(uri);

      final htmlmd = html2md.convert(data.body);
      return DataResponse(
        body: [MarkdownSection(htmlmd)],
        statusCode: data.statusCode,
        title: "Empty Response",
      );
    }

    final response = data;

    final parsedhtml = await compute(html.parse, response.body);

    if (uri.path.contains("/r/")) {
      List threads = parsedhtml.getElementsByClassName("thread");

      List<CommentData> comments_list = [];
      for (var thread in threads) {
        // thread > comment > comment_right > replies > comment > comment_right > comment_body

        if (thread.children.isEmpty) {
          continue;
        }
        final comments = recursive_commentparse(thread.children[0]);
        comments_list.add(comments);
      }

      return DataResponse(
        body: [CommentThreadSection(comments_list)],
        statusCode: response.statusCode,
        title: "Reddit Thread",
      );
    }

    List<Article> post_data = [];
    final posts = parsedhtml.getElementById("posts");

    if (posts != null) {
      final post_list = posts.getElementsByClassName("post");

      for (var post in post_list) {
        final chld = post.children;

        final _ = chld;
        post_data.add(
          Article(
            title: post.getElementsByClassName("post_title")[0].text.trim(),
            content: post.getElementsByClassName("post_body")[0].text.trim(),
            subgroup: post
                .getElementsByClassName("post_subreddit")[0]
                .text
                .trim(),
            author: post.getElementsByClassName("post_author")[0].text.trim(),
            time: post.getElementsByClassName("created")[0].text.trim(),
            upvotes:
                int.tryParse(
                  post
                          .getElementsByClassName("post_score")[0]
                          .attributes['title'] ??
                      "",
                ) ??
                -1,
            url:
                "https://reddit.com${post.getElementsByClassName("post_comments").isNotEmpty ? post.getElementsByClassName("post_comments")[0].attributes['href'] ?? "" : post.getElementsByTagName("a")[0].attributes['href'] ?? ""}",
            thumbnail: '',
          ),
        );
      }
    }
    return DataResponse(
      body: [
        ArticleListSection(
          title: "Homepage",
          layout: LayoutConfig.list,
          articles: post_data,
        ),
      ],
      statusCode: response.statusCode,
      title: "Reddit Posts",
    );
  }
}

CommentData recursive_commentparse(html.Element comment) {
  List<CommentData> parsed_replies = [];
  final replies = comment.getElementsByClassName("replies");

  if (replies.isNotEmpty) {
    final reply_list = replies[0].getElementsByClassName("comment");
    for (var reply in reply_list) {
      try {
        parsed_replies.add(recursive_commentparse(reply));
      } catch (e) {
        parsed_replies.add(
          CommentData(
            id: "Error",
            author: "",
            score: -1,
            content: "Error $e",
            createdAt: DateTime(2017),
            replies: [],
          ),
        );
      }
    }
  }
  return CommentData(
    id: comment.id,
    author: comment.getElementsByClassName("comment_author")[0].text,
    score:
        int.tryParse(comment.getElementsByClassName("comment_score")[0].text) ??
        -1,
    content: comment.querySelector(".comment_body .md")?.text ?? "",
    createdAt:
        DateTime.tryParse(comment.getElementsByClassName("created")[0].text) ??
        DateTime(2017),
    replies: parsed_replies,
  );
}

class RedditCommentParser {
  static List<CommentData> parseComments(String htmlContent) {
    final document = html.parse(htmlContent);
    final commentThreads = document.querySelectorAll('.thread');
    final List<CommentData> allComments = [];

    for (final thread in commentThreads) {
      final comments = _parseCommentNodes(thread);
      allComments.addAll(comments);
    }

    return allComments;
  }

  static List<CommentData> _parseCommentNodes(html.Element parentElement) {
    final List<CommentData> comments = [];
    final commentDivs = parentElement.querySelectorAll('div.comment');

    for (final commentDiv in commentDivs) {
      final commentData = _parseSingleComment(commentDiv);
      if (commentData != null) {
        comments.add(commentData);
      }
    }

    return comments;
  }

  static CommentData? _parseSingleComment(html.Element commentElement) {
    // Get comment id
    final id = commentElement.id;
    if (id.isEmpty) return null;

    // Get author
    final authorElement = commentElement.querySelector('.comment_author');
    final author =
        authorElement?.text.trim().replaceFirst('u/', '') ?? 'unknown';

    // Get content
    final contentElement = commentElement.querySelector('.comment_body .md');
    String content = '';
    if (contentElement != null) {
      content = _extractTextContent(contentElement);
    }

    // Get creation time
    final createdElement = commentElement.querySelector('.created');
    DateTime? createdAt;
    if (createdElement != null) {
      final createdText = createdElement.text.trim();
      createdAt = _parseCreatedTime(createdText);
    }

    // Get score
    final scoreElement = commentElement.querySelector('.comment_score');
    int? score;
    if (scoreElement != null) {
      final scoreText = scoreElement.text
          .trim()
          .replaceAll('k', '000')
          .replaceAll('.', '');
      score = int.tryParse(scoreText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    // Parse replies recursively
    final repliesElement = commentElement.querySelector('blockquote.replies');
    List<CommentData> replies = [];

    if (repliesElement != null) {
      // Look for nested comments within the replies blockquote
      final nestedComments = repliesElement.querySelectorAll('div.comment');
      for (final nestedComment in nestedComments) {
        final reply = _parseSingleComment(nestedComment);
        if (reply != null) {
          replies.add(reply);
        }
      }
    }

    return CommentData(
      id: id,
      author: author,
      content: content,
      createdAt: createdAt,
      score: score,
      replies: replies,
    );
  }

  static String _extractTextContent(html.Element element) {
    final buffer = StringBuffer();

    for (final node in element.nodes) {
      if (node is html.Text) {
        buffer.write(node.text);
      } else if (node is html.Element) {
        if (node.localName == 'a') {
          final href = node.attributes['href'];
          final text = node.text;
          if (href != null && href.startsWith('http')) {
            buffer.write('[$text]($href)');
          } else {
            buffer.write(text);
          }
        } else if (node.localName == 'p') {
          buffer.write('\n${_extractTextContent(node)}\n');
        } else if (node.localName == 'figure') {
          // Handle images in comments
          final imgElement = node.querySelector('img');
          if (imgElement != null) {
            final src = imgElement.attributes['src'];
            buffer.write('[Image: $src]');
          }
        } else {
          buffer.write(_extractTextContent(node));
        }
      }
    }

    return buffer.toString().trim();
  }

  static DateTime? _parseCreatedTime(String createdText) {
    // Handle relative time strings like "3h ago", "2h ago", "1h ago", "2m ago", etc.
    final match = RegExp(r'(\d+)\s*([hdm])\s*ago').firstMatch(createdText);

    if (match != null) {
      final value = int.parse(match.group(1)!);
      final unit = match.group(2)!;

      final now = DateTime.now();

      switch (unit) {
        case 'h':
          return now.subtract(Duration(hours: value));
        case 'd':
          return now.subtract(Duration(days: value));
        case 'm':
          return now.subtract(Duration(minutes: value));
        default:
          return null;
      }
    }

    // Try parsing absolute date
    try {
      return DateTime.parse(createdText);
    } catch (e) {
      return null;
    }
  }
}

class RedlibParser {
  static List<Article> parseArticles(String html) {
    final articles = <Article>[];

    // Regex patterns
    final postPattern = RegExp(
      r'<div class="post"[^>]*id="[^"]*">(.*?)</div>\s*(?:<hr class="sep">|</div>)',
      dotAll: true,
    );
    final titlePattern = RegExp(
      r'<h2 class="post_title">\s*<a href="([^"]+)">([^<]+)</a>',
    );
    final subgroupPattern = RegExp(
      r'<a class="post_subreddit" href="[^"]+">([^<]+)</a>',
    );
    final authorPattern = RegExp(
      r'<a class="post_author[^"]*"[^>]*>u/([^<]+)</a>',
    );
    final timePattern = RegExp(r'<span class="created"[^>]*>([^<]+)</span>');
    final upvotesPattern = RegExp(
      r'<div class="post_score"[^>]*title="[^"]*">\s*([^<]+?)\s*<span',
    );
    final contentPattern = RegExp(
      r'<div class="post_body post_preview">\s*<div class="md">(.*?)</div>',
      dotAll: true,
    );
    final thumbnailPattern = RegExp(
      r'<div class="post_media_content">.*?<img[^>]+src="([^"]+)"',
      dotAll: true,
    );

    final matches = postPattern.allMatches(html);

    for (final match in matches) {
      final postHtml = match.group(1) ?? '';

      // Extract title and URL
      final titleMatch = titlePattern.firstMatch(postHtml);
      final url = titleMatch?.group(1) ?? '';
      final title = titleMatch?.group(2) ?? '';
      if (title.isEmpty) continue;

      // Extract other fields
      final subgroup = subgroupPattern.firstMatch(postHtml)?.group(1) ?? '';
      final author = authorPattern.firstMatch(postHtml)?.group(1) ?? 'unknown';
      final time = timePattern.firstMatch(postHtml)?.group(1) ?? '';

      String upvotesText =
          upvotesPattern.firstMatch(postHtml)?.group(1)?.trim() ?? '0';
      int upvotes = _parseUpvotes(upvotesText);

      String content =
          contentPattern.firstMatch(postHtml)?.group(1)?.trim() ?? '';
      content = _cleanHtml(content);

      String? thumbnail = thumbnailPattern.firstMatch(postHtml)?.group(1);

      articles.add(
        Article(
          title: title,
          content: content.isNotEmpty ? content : '(No text content)',
          subgroup: subgroup,
          author: author,
          time: time,
          upvotes: upvotes,
          url: url,
          thumbnail: thumbnail,
        ),
      );
    }

    return articles;
  }

  static int _parseUpvotes(String text) {
    text = text.trim().toLowerCase();
    if (text.contains('k')) {
      final num = double.tryParse(text.replaceAll('k', '')) ?? 0;
      return (num * 1000).round();
    }
    if (text == '•' || text.isEmpty) return 0;
    return int.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  static String _cleanHtml(String html) {
    // Remove HTML tags
    return html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
