import 'dart:async';
import 'package:puppeteer/puppeteer.dart';
import 'package:zero_browser/client/client.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:zero_browser/model/data.dart';

class CDPInstance {
  Future<Browser>? _browser;
  Page? _page;

  Future<Browser> launch() async {
    if (_browser != null) {
      return await _browser!;
    }

    _browser = puppeteer.launch(headless: false);

    return await _browser!;
  }

  Future<Page> newOrExistingPage(Uri uri) async {
    if (_page != null && !_page!.isClosed) {
      if (_page!.url == uri.toString()) {
        return _page!;
      }
    }

    final browser = await launch();
    _page = await browser.newPage();

    return _page!;
  }

  Future<String> readPage(Uri uri) async {
    final page = await newOrExistingPage(uri);

    await page.goto(uri.toString(), wait: Until.networkIdle);

    return await page.content ?? "";
  }

  Future<void> dispose() async {
    await _page?.close();
    await _browser?.then((b) => b.close());

    _page = null;
    _browser = null;
  }
}

class ChromiumCDP extends RequestTransformer {
  static final CDPInstance instance = CDPInstance();

  ChromiumCDP({Uri? uri}) : super(host: ["*"], uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => ChromiumCDP(uri: uri);

  @override
  Future<DataResponse> getData() async {
    final html = await instance.readPage(uri);
    final md = html2md.convert(html);
    return DataResponse(
      body: [MarkdownSection(md)],
      statusCode: 200,
      title: uri.toString(),
    );
  }
}
