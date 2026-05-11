import 'package:http/http.dart' as http;
import 'package:html2md/html2md.dart' as html2md;
import 'package:zero_browser/client/hosts/basichtml.dart';
import 'package:zero_browser/client/hosts/chrome.dart';
import 'package:zero_browser/client/hosts/localfile.dart';
import 'package:zero_browser/client/internal/browser.dart';
import 'package:zero_browser/model/data.dart';
import 'package:zero_browser/providers/history_provider.dart';
import 'package:zero_browser/utils/uri.dart';

class DataResponse {
  final String title;
  final List<Section> body;
  final int statusCode;

  DataResponse({
    required this.body,
    required this.statusCode,
    required this.title,
  });

  factory DataResponse.fromHttpResponse(http.Response resp, [String? title]) {
    return DataResponse(
      title: title ?? "Response",
      body: [MarkdownSection(resp.body)],
      statusCode: resp.statusCode,
    );
  }

  DataResponse copyWith({dynamic body, int? statusCode, String? title}) {
    return DataResponse(
      body: body ?? this.body,
      statusCode: statusCode ?? this.statusCode,
      title: title ?? this.title,
    );
  }
}

abstract class RequestTransformer {
  final Uri uri;
  final List<String> host;

  RequestTransformer({required this.host, required this.uri});

  RequestTransformer withUri(Uri uri);

  Future<DataResponse> getData() async {
    final response = await http.get(uri);

    // "content-type" -> "text/html; charset=utf-8"

    var contentType = response.headers['content-type'] ?? '';

    if (contentType.contains('text/html')) {
      contentType = 'text/html';
    }

    switch (contentType) {
      case "text/html":
        return useful_html_content(response);
      case "image/jpeg":
      case "image/png":
      case "image/webp":
      case "image/jpg":
      case "image/svg+xml":
      case "image/gif":
      case "image/bmp":
      case "image/tiff":
      case "image/avif":
      case "image/apng":
        return DataResponse(
          body: [
            MediaSection(items: [response.bodyBytes]),
          ],
          statusCode: response.statusCode,
          title: "Image",
        );
      default:
        return DataResponse(
          body: [MarkdownSection("```$contentType\n ${response.body}\n```")],
          statusCode: response.statusCode,
          title: "$contentType ${cleanUri(uri)}",
        );
    }
  }
}

class DefaultRequest extends RequestTransformer {
  DefaultRequest({required super.uri}) : super(host: ["*"]);

  @override
  RequestTransformer withUri(Uri uri) => DefaultRequest(uri: uri);
}

class RequesterRegistry {
  static final List<RequestTransformer> _transformers = [];

  /// Registers a transformer, preventing duplicates and keeping the list sorted
  /// by domain length (longest first) for prefix matching.
  static void register(RequestTransformer transformer) {
    // Prevent duplicates by domain
    if (_transformers.any((t) => t.host == transformer.host)) {
      return;
    }

    _transformers.add(transformer);
    // Sort by domain length descending for more specific matches
    _transformers.sort((a, b) => b.host.length.compareTo(a.host.length));
  }

  /// Resolves the transformer whose domain is the longest prefix of the URI.
  static RequestTransformer resolve(TabData tab, String url) {
    if (url.isEmpty) {
      return BrowserRequest(uri: Uri.parse("browser:newtab"));
    }

    final baseUri = Uri.parse(tab.page.url);
    var uri = baseUri.resolve(url);

    switch (uri.scheme) {
      case "browser":
        return BrowserRequest(uri: uri);
      case "file":
        return Localfile(uri: uri);
      case "chrome":
        return ChromeExtensionRequest(uri: uri);
      case "":
        uri = Uri.parse("https:$uri");
      case "http":
      case "https":
        final template = findResolvers(uri);
        if (template != null) {
          return template.withUri(uri);
        }
    }
    return DefaultRequest(uri: uri);
  }

  // Optional: for debugging or testing
  static List<RequestTransformer> get all => List.unmodifiable(_transformers);

  static void clear() {
    _transformers.clear();
  }

  static RequestTransformer? findResolvers(Uri uri) {
    for (final transformer in _transformers) {
      if (transformer.host.contains(uri.host)) {
        return transformer;
      }
    }
    return null;
  }
}

Future<DataResponse> fetchData(TabData tab, String uri) async {
  final resolver = RequesterRegistry.resolve(tab, uri);

  try {
    final response = await resolver.getData();

    if (response.statusCode == 200) {
      return response;
    } else {
      return response.copyWith(
        body: [
          MarkdownSection(
            'Request failed with status: ${response.statusCode}.',
          ),
        ],
      );
    }
  } catch (e) {
    return DataResponse(
      body: [MarkdownSection("Network error ($e)")],
      statusCode: 500,
      title: "Error",
    );
  }
}
