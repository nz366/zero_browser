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

  static const int feedLimit = 20;
  static const int maxCommentsPerLevel = 50;

  static const int maxCommentDepth = 5;

  // TODO: wait for cache
  final Map<String, String> _cache = {};
  final Map<String, Future<String?>> _pendingRequests = {};

  @override
  RequestProfile get request => RequestProfile(
    getContent: (Client client, String path) async {
      final defaultSection = MarkdownSection(
        "[Top Stories]($websiteHost) | [New]($websiteHost/newest) | "
        "[Ask]($websiteHost/ask) | [Show]($websiteHost/show) | "
        "[Jobs]($websiteHost/jobs)",
      );

      return _request_content(path, client).then((v) {
        v.body.insert(0, defaultSection);
        return v;
      });
    },
  );

  Future<Structure> _request_content(String path, Client client) async {
    final uri = Uri.tryParse(path);

    if (uri == null) {
      return _errorStructure("Invalid URL", 400);
    }

    if (uri.path == '/item') {
      final id = uri.queryParameters['id'];

      if (id == null || id.isEmpty) {
        return _errorStructure("Missing item id", 400);
      }

      return _getItem(client, id);
    }

    if (uri.path == '/user') {
      final username = uri.queryParameters['name'];

      if (username == null || username.isEmpty) {
        return _errorStructure("Missing username", 400);
      }

      return _getUser(client, username);
    }

    switch (uri.path) {
      case '':
      case '/':
        return _getFeed(client, endpoint: 'topstories', title: 'Top Stories');

      case '/new':
        return _getFeed(client, endpoint: 'newstories', title: 'New Stories');

      case '/best':
        return _getFeed(client, endpoint: 'beststories', title: 'Best Stories');

      case '/ask':
        return _getFeed(client, endpoint: 'askstories', title: 'Ask HN');

      case '/show':
        return _getFeed(client, endpoint: 'showstories', title: 'Show HN');

      case '/jobs':
        return _getFeed(client, endpoint: 'jobstories', title: 'Jobs');

      default:
        return _errorStructure("Unknown Hacker News path: ${uri.path}", 404);
    }
  }

  Future<Structure> _getFeed(
    Client client, {
    required String endpoint,
    required String title,
  }) async {
    final responseBody = await _getFirebase(
      client,
      '$firebaseAPI/$endpoint.json',
      throwError: true,
    );

    if (responseBody == null) {
      return _errorStructure("Failed to load $title", 500);
    }

    final decoded = jsonDecode(responseBody);

    if (decoded is! List) {
      return _errorStructure("Invalid response from Hacker News", 500);
    }

    final storyIds = decoded.take(feedLimit).where((id) => id != null).toList();

    final futures = storyIds.map(
      (id) =>
          _getFirebase(client, '$firebaseAPI/item/$id.json', throwError: false),
    );

    final responses = await Future.wait(futures);

    final posts = <Article>[];

    for (var i = 0; i < responses.length; i++) {
      final responseBody = responses[i];

      if (responseBody == null) {
        continue;
      }

      try {
        final item = jsonDecode(responseBody);

        if (item == null || item is! Map) {
          continue;
        }

        final type = item['type'];

        // Feed endpoints can theoretically contain deleted/dead items.
        if (type != 'story' && type != 'job' && type != 'poll') {
          continue;
        }

        final article = _itemToArticle(item, subgroup: endpoint);

        if (article != null) {
          posts.add(article);
        }
      } catch (_) {
        // Ignore malformed individual items instead of failing the whole feed.
        continue;
      }
    }

    return Structure(
      body: [
        ArticleListSection(
          title: "Feed",
          layout: LayoutConfig.list,
          articles: posts,
        ),
      ],
      statusCode: 200,
      title: title,
    );
  }

  Future<Structure> _getItem(Client client, String id) async {
    final responseBody = await _getFirebase(
      client,
      '$firebaseAPI/item/$id.json',
      throwError: true,
    );

    if (responseBody == null) {
      return _errorStructure("Unable to load item", 500);
    }

    final item = jsonDecode(responseBody);

    if (item == null || item is! Map) {
      return _errorStructure("Invalid Hacker News item", 500);
    }

    if (item['deleted'] == true) {
      return Structure(
        body: [
          MarkdownSection(
            "# Deleted Item\n\nThis Hacker News item has been deleted.",
          ),
        ],
        statusCode: 200,
        title: "Deleted Item",
      );
    }

    if (item['dead'] == true) {
      return Structure(
        body: [
          MarkdownSection(
            "# Dead Item\n\nThis Hacker News item is no longer active.",
          ),
        ],
        statusCode: 200,
        title: "Dead Item",
      );
    }

    final type = item['type'];

    switch (type) {
      case 'story':
        return _getStory(client, item);

      case 'comment':
        return _getSingleComment(client, item);

      case 'job':
        return _getJob(item);

      case 'poll':
        return _getPoll(client, item);

      default:
        return _errorStructure("Unsupported Hacker News item type: $type", 400);
    }
  }

  Future<Structure> _getStory(Client client, Map item) async {
    final title = item['title'] ?? 'No Title';

    var markdown = '# $title\n\n';

    // Source URL.
    final url = item['url'];

    if (url != null && url.toString().isNotEmpty) {
      markdown += "Source: ($url)\n\n";
    }

    // Story text.
    final text = item['text'];

    if (text != null && text.toString().isNotEmpty) {
      markdown += html2md.convert(text.toString());

      markdown += "\n\n";
    }

    // Metadata.
    final author = item['by'] ?? 'unknown';
    final score = item['score'] ?? 0;

    markdown += "---\n\n";
    markdown += "**Author:** $author\n\n";
    markdown += "**Score:** $score\n\n";

    final comments = await fetchcomments(
      client,
      item['kids'] ?? [],
      null,
      depth: 0,
    );

    return Structure(
      body: [MarkdownSection(markdown), CommentThreadSection(comments)],
      statusCode: 200,
      title: title,
    );
  }

  Future<Structure> _getJob(Map item) async {
    final title = item['title'] ?? 'Hacker News Job';

    var markdown = '# $title\n\n';

    if (item['text'] != null) {
      markdown += html2md.convert(item['text'].toString());

      markdown += "\n\n";
    }

    if (item['url'] != null) {
      markdown += "Apply / Source: (${item['url']})\n\n";
    }

    markdown += "---\n\n";
    markdown += "**Company / Author:** ${item['by'] ?? 'unknown'}\n\n";

    return Structure(
      body: [MarkdownSection(markdown)],
      statusCode: 200,
      title: title,
    );
  }

  Future<Structure> _getPoll(Client client, Map item) async {
    final title = item['title'] ?? 'Hacker News Poll';

    var markdown = '# $title\n\n';

    if (item['text'] != null) {
      markdown += html2md.convert(item['text'].toString());

      markdown += "\n\n";
    }

    final parts = item['parts'];

    if (parts is List && parts.isNotEmpty) {
      markdown += "## Options\n\n";

      for (final partId in parts) {
        final partBody = await _getFirebase(
          client,
          '$firebaseAPI/item/$partId.json',
          throwError: false,
        );

        if (partBody == null) {
          continue;
        }

        try {
          final part = jsonDecode(partBody);

          if (part is Map) {
            final option = part['text'] ?? 'Unknown option';
            final score = part['score'] ?? 0;

            markdown += "- $option — **$score votes**\n";
          }
        } catch (_) {
          continue;
        }
      }

      markdown += "\n";
    }

    return Structure(
      body: [MarkdownSection(markdown)],
      statusCode: 200,
      title: title,
    );
  }

  // ===========================================================================
  // SINGLE COMMENT
  // ===========================================================================

  Future<Structure> _getSingleComment(Client client, Map item) async {
    final author = item['by'] ?? 'unknown';

    final text = html2md.convert(item['text'] ?? '').replaceAll(r'\\', '');

    final markdown =
        '''
# Comment

**Author:** $author

$text
''';

    final replies = await fetchcomments(
      client,
      item['kids'] ?? [],
      null,
      depth: 0,
    );

    return Structure(
      body: [MarkdownSection(markdown), CommentThreadSection(replies)],
      statusCode: 200,
      title: "Comment by $author",
    );
  }

  // ===========================================================================
  // USERS
  // ===========================================================================

  Future<Structure> _getUser(Client client, String username) async {
    final responseBody = await _getFirebase(
      client,
      '$firebaseAPI/user/${Uri.encodeComponent(username)}.json',
      throwError: true,
    );

    if (responseBody == null) {
      return _errorStructure("Unable to load user", 500);
    }

    final user = jsonDecode(responseBody);

    if (user == null || user is! Map) {
      return _errorStructure("User not found", 404);
    }

    final createdAt = user['created'] != null
        ? DateTime.fromMillisecondsSinceEpoch((user['created'] ?? 0) * 1000)
        : null;

    var markdown = '# Hacker News User: $username\n\n';

    markdown += "**Karma:** ${user['karma'] ?? 0}\n\n";

    if (createdAt != null) {
      markdown += "**Created:** ${createdAt.toString()}\n\n";
    }

    if (user['about'] != null) {
      markdown += "## About\n\n";
      markdown += html2md.convert(user['about'].toString());
      markdown += "\n\n";
    }

    final submitted = user['submitted'];

    if (submitted is List) {
      markdown += "## Submitted Items\n\n";

      // Don't fetch every submission. This page should remain cheap.
      final limitedSubmitted = submitted.take(20);

      for (final id in limitedSubmitted) {
        markdown += "- [Item $id]($websiteHost/item?id=$id)\n";
      }
    }

    return Structure(
      body: [MarkdownSection(markdown)],
      statusCode: 200,
      title: username,
    );
  }

  // ===========================================================================
  // COMMENTS
  // ===========================================================================

  Future<List<CommentData>> fetchcomments(
    Client client,
    List<dynamic> items,
    TimeOut? timeout, {
    int depth = 0,
  }) async {
    // Stop deep recursion.
    if (depth >= maxCommentDepth) {
      return [];
    }

    if (items.isEmpty) {
      return [];
    }

    // Don't request thousands of comments from a huge thread.
    final limitedItems = items.take(maxCommentsPerLevel).toList();

    final futures = <Future<CommentData?>>[];

    for (final element in limitedItems) {
      futures.add(_fetchComment(client, element, timeout, depth));
    }

    final results = await Future.wait(futures);

    return results.whereType<CommentData>().toList();
  }

  Future<CommentData?> _fetchComment(
    Client client,
    dynamic element,
    TimeOut? timeout,
    int depth,
  ) async {
    if (timeout != null && timeout.isExpired) {
      return CommentData(
        id: element.toString(),
        author: "[System]",
        content: "Error: Timeout",
        createdAt: DateTime.now(),
        replies: [],
      );
    }

    final commentResponse = await _getFirebase(
      client,
      '$firebaseAPI/item/$element.json',
      throwError: false,
    );

    if (commentResponse == null) {
      return CommentData(
        id: element.toString(),
        author: "[System]",
        content: "Error loading comment",
        createdAt: DateTime.now(),
        replies: [],
      );
    }

    try {
      final comment = jsonDecode(commentResponse);

      if (comment == null || comment is! Map) {
        return null;
      }

      // Deleted comments should not recursively fetch their children.
      if (comment['deleted'] == true) {
        return CommentData(
          id: element.toString(),
          author: "[deleted]",
          content: "[deleted]",
          createdAt: DateTime.now(),
          replies: [],
        );
      }

      if (comment['dead'] == true) {
        return CommentData(
          id: element.toString(),
          author: "[dead]",
          content: "[dead comment]",
          createdAt: DateTime.now(),
          replies: [],
        );
      }

      if (comment['type'] != 'comment') {
        return null;
      }

      final htmlmd = html2md
          .convert(comment['text'] ?? '')
          .replaceAll(r'\\', '');

      final kids = comment['kids'];

      final replies = await fetchcomments(
        client,
        kids is List ? kids : [],
        timeout,
        depth: depth + 1,
      );

      return CommentData(
        content: htmlmd,
        author: comment['by'] ?? 'unknown',
        id: element.toString(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (comment['time'] ?? 0) * 1000,
        ),
        replies: replies,
      );
    } catch (_) {
      return CommentData(
        id: element.toString(),
        author: "[System]",
        content: "Error: Invalid Comment",
        createdAt: DateTime.now(),
        replies: [],
      );
    }
  }

  Future<String?> _getFirebase(
    Client client,
    String url, {
    bool throwError = false,
  }) async {
    final cached = _cache[url];

    if (cached != null) {
      return cached;
    }

    final pending = _pendingRequests[url];

    if (pending != null) {
      return pending;
    }

    final future = _performFirebaseRequest(client, url, throwError: throwError);

    _pendingRequests[url] = future;

    try {
      final result = await future;

      if (result != null) {
        _cache[url] = result;
      }

      return result;
    } finally {
      _pendingRequests.remove(url);
    }
  }

  Future<String?> _performFirebaseRequest(
    Client client,
    String url, {
    required bool throwError,
  }) async {
    try {
      final response = await client.httpRequest(url, throwError: throwError);

      if (response.statusCode != 200) {
        return null;
      }

      return response.body;
    } catch (_) {
      if (throwError) {
        rethrow;
      }

      return null;
    }
  }

  Article? _itemToArticle(Map item, {required String subgroup}) {
    final id = item['id'];

    if (id == null) {
      return null;
    }

    final type = item['type'];

    final title =
        item['title'] ?? (type == 'job' ? 'Hacker News Job' : 'No Title');

    String content = '';

    if (item['url'] != null) {
      content += "Source: (${item['url']})\n\n";
    }

    if (item['text'] != null) {
      content += html2md.convert(item['text'].toString());
    }

    return Article(
      title: title.toString(),
      content: content,
      author: item['by'] ?? 'unknown',
      time: DateTime.fromMillisecondsSinceEpoch(
        (item['time'] ?? 0) * 1000,
      ).toString(),
      upvotes: item['score'] ?? 0,
      subgroup: subgroup,
      url: '$websiteHost/item?id=$id',
      thumbnail: '',
    );
  }

  Structure _errorStructure(String message, int statusCode) {
    return Structure(
      body: [MarkdownSection('# Hacker News Error\n\n$message')],
      statusCode: statusCode,
      title: "Hacker News",
    );
  }
}
