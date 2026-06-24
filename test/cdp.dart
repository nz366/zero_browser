import 'package:puppeteer/puppeteer.dart';

void main() async {
  // start a chromium browser with remote debugging, e.g.
  // browser --remote-debugging-port=9222
  // var browser = await puppeteer.connect(
  //   browserWsEndpoint: 'ws://localhost:9222',
  // );

  var browser = await puppeteer.launch(headless: false);

  // Open a new tab
  var myPage = await browser.newPage();

  // Go to a page and wait to be fully loaded
  await myPage.goto(
    'https://pub.dev/documentation/puppeteer/latest',
    wait: Until.networkIdle,
  );

  // Do something... See other examples
  await myPage.screenshot();
  await myPage.pdf();
  await myPage.evaluate<String>('() => document.title');

  // Gracefully close the browser's process
  await browser.close();
}
