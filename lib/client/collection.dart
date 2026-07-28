import 'package:zero_browser/client/hosts/bluebird.dart';
import 'package:zero_browser/client/hosts/galleries.dart';
import 'package:zero_browser/client/hosts/gitea.dart';
import 'package:zero_browser/client/hosts/hackernews.dart';
import 'package:zero_browser/client/hosts/markdown.dart';
import 'package:zero_browser/client/hosts/redlib.dart';
import 'package:zero_browser/client/hosts/mediaWiki.dart';
import 'package:zero_browser/client/registry.dart';

void registerDefaults() {
  for (var element in [
    MediaWikiSite(),
    HackernewsSite(),
    MarkdownSite(),
    RedditSite(),
    GithubSite(),
    GiteaSite(),
    GitlabSite(),
    GallerySite(),
    BlueBirdSite(),
  ]) {
    try {
      HostRegistry.register(element);
    } catch (e) {
      print(e);
    }
  }
}
