import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/model.dart';

class MarkdownSite implements SiteProfile {
  @override
  List<String> get domains => ["blog.cloudflare.com"];

  @override
  RequestProfile get request => RequestProfile(
    getContent: (Client client, String path) async {
      final response = await client.markdownRequest(path);
      return Structure(
        body: [MarkdownSection(response.body)],
        statusCode: response.statusCode,
        title: "Markdown Content",
      );
    },
  );
}
