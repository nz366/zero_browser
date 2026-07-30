import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/client/hosts/basichtml.dart';
import 'package:zero_browser/model/sites.dart';

class RedditSite implements SiteProfile {
  @override
  List<String> get domains => ['www.reddit.com', "reddit.com"];

  @override
  RequestProfile get request => RequestProfile(
    getContent: (Client client, String path) async {
      final uri = Uri.parse(path);
      final response = await client.httpRequest(path, throwError: true);
      final parsedhtml = await compute(html.parse, response.body);
      if (uri.pathSegments.isEmpty) {
        return homepage(parsedhtml);
      } else if (uri.pathSegments[0] == 'r') {
        if (uri.pathSegments[2] == 'comments') {
          return postthread(parsedhtml);
        } else {
          return subredditPage(parsedhtml);
        }
      } else if (uri.pathSegments[0] == 'user' || uri.pathSegments[0] == 'u') {
        return userpage(parsedhtml);
      }
      return defaultHtml(parsedhtml, "Reddit Page");
    },
  );
}

Future<Structure> subredditPage(html.Document parsedhtml) async {
  return defaultHtml(parsedhtml, "Subreddits");
}

Future<Structure> homepage(html.Document parsedhtml) async {
  return defaultHtml(parsedhtml, "Home | reddit.com");
}

Future<Structure> userpage(html.Document parsedhtml) async {
  return defaultHtml(parsedhtml, "User | reddit.com");
}

Future<Structure> postthread(html.Document parsedhtml) async {
  return defaultHtml(parsedhtml, "Post | reddit.com");
}
