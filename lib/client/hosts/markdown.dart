import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

class MarkdownRequest extends RequestTransformer {
  MarkdownRequest({Uri? uri})
    : super(host: ["blog.cloudflare.com"], uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => MarkdownRequest(uri: uri);

  @override
  Future<DataResponse> getData() async {
    final resp = await http.get(uri, headers: {'Accept': 'text/markdown'});
    // TODO: Split up markdown sections

    return DataResponse(
      body: [MarkdownSection(resp.body)],
      statusCode: resp.statusCode,
      title: "Markdown Content",
    );
  }
}
