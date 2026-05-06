import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

class CurlRequest extends RequestTransformer {
  CurlRequest({Uri? uri}) : super(host: ["curl.com"], uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => CurlRequest(uri: uri);

  @override
  Future<DataResponse> getData() async {
    final result = await Process.run('curl', ['-L', uri.toString()]);
    final data = http.Response(
      result.stdout.toString(),
      result.exitCode == 0 ? 200 : 500,
      reasonPhrase: result.exitCode == 0 ? null : result.stderr.toString(),
    );
    if (data.statusCode != 200) {
      return DataResponse(
        body: [MarkdownSection("Curl failed: ${data.reasonPhrase}")],
        statusCode: 500,
        title: "Curl Error",
      );
    }
    return DataResponse(
      body: [MarkdownSection(data.body)],
      statusCode: 200,
      title: "Curl Response",
    );
  }
}
