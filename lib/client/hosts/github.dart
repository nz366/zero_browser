import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

final githubhosts = ["codeberg.org", "github.com"];

class GiteaRequest extends RequestTransformer {
  GiteaRequest({Uri? uri}) : super(host: githubhosts, uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => GiteaRequest(uri: uri);

  @override
  Future<DataResponse> getData() async {
    if (uri.path == "") {
      return DataResponse(
        body: [
          FormSection(
            fields: {"search": TextField(name: "search", label: "Search")},
          ),
        ],
        statusCode: 200,
        title: "Github",
      );
    }

    String host = '';
    String name = '';
    switch (uri.host) {
      case "github.com":
        host = "raw.githubusercontent.com";
        name = 'Github';
        break;
      case "codeberg.org":
        host = "codeberg.org";
        name = 'Codeberg';
        break;
    }

    Uri pageReadme = uri;

    if (!uri.path.contains('refs/')) {
      pageReadme = Uri.https(host, '${uri.path}/refs/heads/master/README.md');
    }

    final data = await http.get(pageReadme);

    return DataResponse(
      body: [MarkdownSection(data.body)],
      statusCode: 200,
      title: name,
    );
  }
}
