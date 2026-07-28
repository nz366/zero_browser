import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/client/hosts/basichtml.dart';
import 'package:zero_browser/model/model.dart';

class GallerySite implements SiteProfile {
  @override
  List<String> get domains => ["instagram.com", "pinterest.com", "imgur.com"];

  @override
  RequestProfile get request => RequestProfile(
    getContent: (Client client, String path) async {
      final response = await client.httpRequest(path);
      return defaultHtmlString(response.body, "$path gallery");
    },
  );
}
