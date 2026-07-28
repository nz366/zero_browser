import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:puppeteer/puppeteer.dart';

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

class ChromiumCDP {
  static final CDPInstance instance = CDPInstance();

  Future<http.Response> getData(String url) async {
    try {
      final html = await instance.readPage(Uri.parse(url));

      return http.Response(html, 200);
    } catch (e) {
      return http.Response("Error", 500);
    }
  }
}
