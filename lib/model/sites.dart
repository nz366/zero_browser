import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

class RequestProfile {
  final Future<Structure> Function(Client client, String path) getContent;

  RequestProfile({required this.getContent});

  RequestProfile copyWith({
    Future<Structure> Function(Client client, String path)? getContent,
  }) {
    return RequestProfile(getContent: getContent ?? this.getContent);
  }
}

abstract class SiteProfile {
  final List<String> domains;
  final RequestProfile request;

  SiteProfile({required this.domains, required this.request});
}

class Structure {
  final String title;
  final List<Section> body;

  Structure({required this.body, required this.title, int? statusCode});
}
