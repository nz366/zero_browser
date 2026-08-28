import 'package:flutter_test/flutter_test.dart';
import 'package:zero_browser/model/model.dart';
import 'package:zero_browser/providers/history_provider.dart';

void main() {
  test('Form section query parameters test', () {
    final testQuery = FormSection(
      title: "query_title",
      fields: {"search": TextField(name: "search", label: "Search")},
    );

    testQuery.fields["search"]?.value = "Hello World!";

    final uri = newFormUri(Uri.parse("https://example.com"), testQuery);

    expect(uri.queryParameters.containsKey("search"), isTrue);

    final result = Uri.decodeComponent(uri.queryParameters["search"]!);
    expect(result, "Hello World!");
  });
}
