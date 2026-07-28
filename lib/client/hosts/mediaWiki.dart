import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/client/hosts/basichtml.dart';
import 'package:zero_browser/model/sites.dart';

class MediaWikiSite implements SiteProfile {
  @override
  List<String> get domains => ["wikipedia.org", "wiki.archlinux.org"];

  @override
  RequestProfile get request => RequestProfile(
    getContent: (Client client, String path) async {
      final response = await client.httpRequest(path);
      return defaultHtmlString(response.body, "MediaWiki");
    },
  );
}
