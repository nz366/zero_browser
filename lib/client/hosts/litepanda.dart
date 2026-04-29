import 'package:zero_browser/client/client.dart';

class Litepanda extends RequestTransformer {
  Litepanda({required super.host, required super.uri});

  @override
  RequestTransformer withUri(Uri uri) {
    // TODO: implement withUri
    throw UnimplementedError();
  }
}
