import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

class BlueBirdRequest extends RequestTransformer {
  BlueBirdRequest({Uri? uri})
    : super(host: ["xcancel.com", "twitter.com", "x.com"], uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => BlueBirdRequest(uri: uri);

  @override
  Future<DataResponse> getData() async {
    final uri = replace_with_fallback(host.first, super.uri);

    final response = await http.get(uri);

    return DataResponse(
      title: "Bluebird: $uri",
      body: [MarkdownSection("${response.body}")],
      statusCode: 200,
    );
  }
}

Uri replace_with_fallback(String host, Uri uri) {
  return Uri.https(host, uri.path);
}
