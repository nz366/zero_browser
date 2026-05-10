import 'package:zero_browser/model/data.dart';
import 'package:zero_browser/providers/history_provider.dart';

main() {
  final test_query = FormSection(
    title: "query_title",
    fields: {"search": TextField(name: "search", label: "Search")},
  );

  test_query.fields["search"]?.value = "Hello World!";

  final uri = newFormUri(Uri.parse("https://example.com"), test_query);

  assert(uri.queryParameters.containsKey("search"));

  final result = Uri.decodeComponent(uri.queryParameters["search"]!);
  assert(result == "Hello World!");
}
