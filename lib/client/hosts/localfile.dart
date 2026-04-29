import 'dart:io';

import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

class Localfile extends RequestTransformer {
  Localfile({Uri? uri}) : super(host: ["*"], uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => Localfile(uri: uri);

  @override
  Future<DataResponse> getData() async {
    final file = File(uri.path);
    final content = await file.readAsString();
    return DataResponse(
      title: uri.path,
      body: [MarkdownSection(content)],
      statusCode: 200,
    );
  }
}
