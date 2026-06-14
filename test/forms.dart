import 'package:zero_browser/model/data.dart';
import 'package:zero_browser/providers/history_provider.dart';

void main() {
  final testQuery = FormSection(
    title: "query_title",
    fields: {"search": TextField(name: "search", label: "Search")},
  );

  testQuery.fields["search"]?.value = "Hello World!";

  final uri = newFormUri(Uri.parse("https://example.com"), testQuery);

  assert(uri.queryParameters.containsKey("search"));

  final result = Uri.decodeComponent(uri.queryParameters["search"]!);
  assert(result == "Hello World!");
}
