import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/client/hosts/basichtml.dart';
import 'package:zero_browser/model/data.dart';

class Mediawiki extends RequestTransformer {
  Mediawiki({Uri? uri})
    : super(
        host: ['en.wikipedia.org', 'wikimedia.org', 'wiki.archlinux.org'],
        uri: uri ?? Uri(),
      );

  @override
  RequestTransformer withUri(Uri uri) => Mediawiki(uri: uri);

  @override
  Future<DataResponse> getData() async {
    http.Response resp = await http.get(uri);

    final body = resp.body;

    return DataResponse(
      body: parseHtmlSource(body),
      statusCode: resp.statusCode,
      title: "Wikipedia",
    );
  }

  List<Section> parseHtmlSource(String body) {
    final content = cleanHtmlSource(body);
    return documentToSections(content);
  }
}
