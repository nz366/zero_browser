import 'package:flutter_test/flutter_test.dart';
import 'package:zero_browser/utils/uri.dart';

void main() {
  test('Test Uri', () {
    final a = Uri.parse(
      "example.com",
    ).insertOrIgnore(newScheme: "https://").toString();

    expect(a, "https://example.com");
  });

  test('Test Uri Resolve', () {
    final a = Uri.parse(
      "a/x/c",
    ).resolveWithBase(base: Uri.parse("https://example.com")).toString();

    expect(a, "https://example.com/a/x/c");
  });
  test('Test Malformed', () {
    [
      "//example.com/path/to",
      "://example.com/path/to",
      "example.com/path/to",
      "/path/to",
    ].forEach((url) {
      final u = UriUtils.parseMalformed(
        url,
        defaultScheme: "https",
        defaultHostSegments: ["example.com"],
      );
      expect(u.toString(), "https://example.com/path/to");
    });
  });
}
