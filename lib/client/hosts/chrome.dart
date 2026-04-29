import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

final ChromeExtensionRequestHost extensionHost = ChromeExtensionRequestHost();

void startChromeExtensionRequestHost() {
  extensionHost.start();
}

class ChromeExtensionRequestHost {
  WebSocket? _socket;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  int _requestId = 0;

  bool get isConnected => _socket == null;

  Future<void> start() async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 9191);
      server.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          _socket = await WebSocketTransformer.upgrade(request);
          _socket!.listen(
            (data) {
              final payload = jsonDecode(data);
              if (payload['requestId'] != null) {
                final completer =
                    _pendingRequests[payload['requestId'].toString()];
                if (completer != null) {
                  completer.complete(payload);
                  _pendingRequests.remove(payload['requestId'].toString());
                }
              }
            },
            onDone: () {
              _socket = null;
            },
          );
        }
      });
    } catch (e) {
      print('Chrome extension host start error: $e');
    }
  }

  Future<Map<String, dynamic>> fetchFromExtension(String url) async {
    if (_socket == null) {
      throw Exception(
        "Chrome extension not connected. Make sure the extension is running.",
      );
    }
    final id = (_requestId++).toString();
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    _socket!.add(jsonEncode({"action": "fetch", "requestId": id, "url": url}));

    return completer.future.timeout(Duration(seconds: 3000));
  }
}

class PartialChromeRequests extends RequestTransformer {
  PartialChromeRequests({Uri? uri}) : super(host: ["*"], uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => PartialChromeRequests(uri: uri);

  @override
  Future<DataResponse> getData() async {
    // todo: bind tab.id to this request reload should use this id to decide to create new tab.
    try {
      String targetUrl = uri.path;
      if (targetUrl.startsWith('/')) {
        targetUrl = targetUrl.substring(1);
      }
      targetUrl = uri.host + (targetUrl.isNotEmpty ? '/$targetUrl' : '');
      if (!targetUrl.contains("://") && targetUrl.isNotEmpty) {
        targetUrl = "https://$targetUrl";
      }

      if (!extensionHost.isConnected) {
        return DataResponse(
          title: "No Connection",
          body: [MarkdownSection("No chrome extension connected.\n")],
          statusCode: 200,
        );
      }

      final result = await extensionHost.fetchFromExtension(targetUrl);

      final images = result['images'] as List<dynamic>? ?? [];
      final lists = result['lists'] as List<dynamic>? ?? [];

      if (images.isEmpty && lists.isEmpty) {
        return DataResponse(
          title: "Extension: $targetUrl",
          body: [MarkdownSection("No media found\n ${result.toString()}")],
          statusCode: 404,
        );
      }

      final articles = images.map((e) {
        return Article(
          title: e['alt']?.toString() ?? 'image',
          url: e['src']?.toString() ?? '',
          content: '',
          subgroup: '',
          author: '',
          time: '',
          upvotes: 0,
          thumbnail: e['src']?.toString() ?? '',
        );
      }).toList();

      return DataResponse(
        title: "$targetUrl (chrome)",
        body: [
          ArticleListSection(
            title: "Images from $targetUrl",
            layout: LayoutConfig.grid,
            articles: articles,
          ),
        ],
        statusCode: 200,
      );
    } catch (e) {
      return DataResponse(
        title: "Extension Error",
        body: [MarkdownSection("# Error\\n\\n$e")],
        statusCode: 500,
      );
    }
  }
}

class ChromeExtensionRequest extends RequestTransformer {
  ChromeExtensionRequest({Uri? uri}) : super(host: ["*"], uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => ChromeExtensionRequest(uri: uri);

  @override
  Future<DataResponse> getData() async {
    // todo: bind tab.id to this request reload should use this id to decide to create new tab.
    try {
      String targetUrl = uri.path;
      if (targetUrl.startsWith('/')) {
        targetUrl = targetUrl.substring(1);
      }
      targetUrl = uri.host + (targetUrl.isNotEmpty ? '/$targetUrl' : '');
      if (!targetUrl.contains("://") && targetUrl.isNotEmpty) {
        targetUrl = "https://$targetUrl";
      }

      final result = await extensionHost.fetchFromExtension(targetUrl);

      final images = result['images'] as List<dynamic>? ?? [];
      final lists = result['lists'] as List<dynamic>? ?? [];

      if (images.isEmpty && lists.isEmpty) {
        return DataResponse(
          title: "Extension: $targetUrl",
          body: [MarkdownSection("No media found\n ${result.toString()}")],
          statusCode: 404,
        );
      }

      final articles = images.map((e) {
        return Article(
          title: e['alt']?.toString() ?? 'image',
          url: e['src']?.toString() ?? '',
          content: '',
          subgroup: '',
          author: '',
          time: '',
          upvotes: 0,
          thumbnail: e['src']?.toString() ?? '',
        );
      }).toList();

      // final mdBuffer = StringBuffer();

      // if (images.isEmpty && lists.isEmpty) {
      //   mdBuffer.writeln("*No media found*");
      // }

      // if (images.isNotEmpty) {
      //   mdBuffer.writeln("# Images from $targetUrl");
      //   for (var img in images) {
      //     final alt = img['alt']?.toString().replaceAll('\n', ' ') ?? 'image';
      //     final src = img['src']?.toString() ?? '';
      //     if (src.isNotEmpty) {
      //       mdBuffer.writeln("![$alt]($src)");
      //       mdBuffer.writeln();
      //     }
      //   }
      // }

      // if (lists.isNotEmpty) {
      //   mdBuffer.writeln("# Lists");
      //   for (var list in lists) {
      //     mdBuffer.writeln(
      //       "- `<${list['tag']}>` with ${list['imgCount']} images and ${list['videoCount']} videos (depth ${list['depth']})",
      //     );
      //   }
      // }

      return DataResponse(
        title: "Extension: $targetUrl",
        body: [
          ArticleListSection(
            title: "Images from $targetUrl",
            layout: LayoutConfig.grid,
            articles: articles,
          ),
        ],
        statusCode: 200,
      );
    } catch (e) {
      return DataResponse(
        title: "Extension Error",
        body: [MarkdownSection("# Error\\n\\n$e")],
        statusCode: 500,
      );
    }
  }
}
