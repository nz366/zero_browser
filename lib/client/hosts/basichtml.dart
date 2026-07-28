import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:html/dom.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html;
import 'package:html2md/html2md.dart' as html2md;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/model.dart';

String? htmlDocumentTitle(Document document) {
  return document.querySelector("title")?.text ??
      document.querySelector("meta[property='og:title']")?.text;
}

class HtmlProfile implements RequestProfile {
  @override
  RequestProfile copyWith({getContent}) {
    return this;
  }

  @override
  Future<Structure> Function(Client client, String path) get getContent =>
      getContentstatic;

  static Future<Structure> getContentstatic(Client client, String path) async {
    final response = await client.httpRequest(path);

    final contentType = ContentType.parse(
      response.headers['content-type'] ?? '',
    );

    switch (contentType.mimeType) {
      case "text/html":
        return defaultHtmlString(response.body, path);
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
        return Structure(
          body: [
            MediaSection(
              items: [
                PreLoadedFile(response.bodyBytes, name: path.split("/").last),
              ],
            ),
          ],
          title: path,
        );

      default:
        return Structure(
          body: [
            MediaSection(
              items: [
                PreLoadedFile(response.bodyBytes, name: path.split("/").last),
              ],
              downloadMode: true,
            ),
          ],
          title: path,
          statusCode: response.statusCode,
        );
    }
  }
}

class FileProfile implements RequestProfile {
  @override
  RequestProfile copyWith({getContent}) {
    return this;
  }

  @override
  Future<Structure> Function(Client client, String path) get getContent =>
      getContentstatic;

  static Future<Structure> getContentstatic(Client client, String path) async {
    final response = await client.localRequest(path);
    return defaultHtmlString(response.body, path);
  }
}

Future<Structure> defaultHtmlString(String data, String fallbackTitle) async {
  final document = await compute(html.parse, data);
  return defaultHtml(document, fallbackTitle);
}

Structure defaultHtml(html.Document document, String fallbackTitle) {
  final title = htmlDocumentTitle(document);
  document.querySelectorAll('style').forEach((element) => element.remove());
  document.querySelectorAll('script').forEach((element) => element.remove());

  final body = document.querySelectorAll("body");

  final content = html2md.convert(body.first.innerHtml);

  return Structure(
    body: [MarkdownSection(content)],
    statusCode: 200,
    title: title ?? fallbackTitle,
  );
}
