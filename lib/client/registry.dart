import 'package:zero_browser/client/hosts/basichtml.dart';
import 'package:zero_browser/client/internal/browser.dart';
import 'package:zero_browser/model/model.dart';
import 'package:zero_browser/utils/utils.dart';

class HostRegistry {
  HostRegistry._();

  static UrlPatternRegistry<RequestProfile?> profiles = UrlPatternRegistry();

  static RequestProfile resolve(String url) {
    if (url.startsWith("browser://")) return BrowserPageProfile();
    if (url.startsWith("file://")) return FileProfile();

    return profiles.match(url) ?? HtmlProfile();
  }

  static void register(SiteProfile profile) {
    for (var element in profile.domains) {
      profiles.register(element, profile.request);
    }
  }
}
