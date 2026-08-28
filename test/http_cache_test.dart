import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/client/http_cache.dart';

void main() {
  group('ClientCache tests', () {
    test('Cache get, set, containsKey, remove, clear', () {
      final cache = ClientCache();
      final uri = Uri.parse('https://example.com');
      final response = ResponseDetails.fromGetRequest(
        http.Response('Hello World', 200),
        uri: uri,
      );

      expect(cache.containsKey('https://example.com'), false);
      expect(cache.get('https://example.com'), null);

      cache.set('https://example.com', response);

      expect(cache.containsKey('https://example.com'), true);
      expect(cache.get('https://example.com')?.body, 'Hello World');

      cache.remove('https://example.com');
      expect(cache.containsKey('https://example.com'), false);

      cache.set('https://example.com', response);
      cache.clear();
      expect(cache.containsKey('https://example.com'), false);
    });

    test('getOrFetch caches successful 200 response', () async {
      final cache = ClientCache();
      final uri = Uri.parse('https://example.com/api');
      int fetchCount = 0;

      Future<ResponseDetails> fetch() async {
        fetchCount++;
        return ResponseDetails.fromGetRequest(
          http.Response('Data', 200),
          uri: uri,
        );
      }

      final res1 = await cache.getOrFetch('https://example.com/api', fetch);
      expect(res1.body, 'Data');
      expect(fetchCount, 1);

      final res2 = await cache.getOrFetch('https://example.com/api', fetch);
      expect(res2.body, 'Data');
      expect(fetchCount, 1); // Served from cache
    });

    test('Cache invalidation via TTL / maxAge', () async {
      final cache = ClientCache();
      final uri = Uri.parse('https://example.com/ttl');
      int fetchCount = 0;

      Future<ResponseDetails> fetch() async {
        fetchCount++;
        return ResponseDetails.fromGetRequest(
          http.Response('V$fetchCount', 200),
          uri: uri,
        );
      }

      final res1 = await cache.getOrFetch(
        'https://example.com/ttl',
        fetch,
        maxAge: const Duration(milliseconds: 50),
      );
      expect(res1.body, 'V1');

      // Immediate call returns cached V1
      final res2 = await cache.getOrFetch(
        'https://example.com/ttl',
        fetch,
        maxAge: const Duration(milliseconds: 50),
      );
      expect(res2.body, 'V1');

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 60));

      final res3 = await cache.getOrFetch(
        'https://example.com/ttl',
        fetch,
        maxAge: const Duration(milliseconds: 50),
      );
      expect(res3.body, 'V2');
      expect(fetchCount, 2);
    });

    test('Cache invalidation via forceRefresh and invalidate', () async {
      final cache = ClientCache();
      final uri = Uri.parse('https://example.com/refresh');
      int fetchCount = 0;

      Future<ResponseDetails> fetch() async {
        fetchCount++;
        return ResponseDetails.fromGetRequest(
          http.Response('Val$fetchCount', 200),
          uri: uri,
        );
      }

      await cache.getOrFetch('https://example.com/refresh', fetch);
      expect(fetchCount, 1);

      // Force refresh invalidates cache
      final res2 = await cache.getOrFetch(
        'https://example.com/refresh',
        fetch,
        forceRefresh: true,
      );
      expect(res2.body, 'Val2');
      expect(fetchCount, 2);

      // Explicit invalidate
      cache.invalidate('https://example.com/refresh');
      expect(cache.containsKey('https://example.com/refresh'), false);
    });

    test('invalidateWhere invalidates matching keys', () {
      final cache = ClientCache();
      final uri = Uri.parse('https://example.com');

      cache.set(
        'https://example.com/1',
        ResponseDetails.fromGetRequest(http.Response('1', 200), uri: uri),
      );
      cache.set(
        'https://example.com/2',
        ResponseDetails.fromGetRequest(http.Response('2', 200), uri: uri),
      );

      cache.invalidateWhere((key, response) => key.endsWith('/1'));
      expect(cache.containsKey('https://example.com/1'), false);
      expect(cache.containsKey('https://example.com/2'), true);
    });

    test('Server cache revalidation with ETag and 304 Not Modified', () async {
      final cache = ClientCache();
      final uri = Uri.parse('https://example.com/etag');
      Map<String, String>? capturedHeaders;

      Future<http.Response> fetch([Map<String, String>? headers]) async {
        capturedHeaders = headers;
        if (headers != null && headers['If-None-Match'] == '"v1"') {
          return http.Response('', 304);
        }
        return http.Response('Content V1', 200, headers: {'etag': '"v1"'});
      }

      // Initial fetch -> status 200 with ETag header
      final res1 = await cache.getOrFetch('https://example.com/etag', fetch);
      expect(res1.body, 'Content V1');
      expect(capturedHeaders, null);

      // Second fetch (expired / stale check) -> sends If-None-Match header, gets 304
      final res2 = await cache.getOrFetch('https://example.com/etag', fetch);
      expect(res2.body, 'Content V1'); // Served cached content on 304
      expect(capturedHeaders?['If-None-Match'], '"v1"');
    });

    test(
      'Server cache revalidation with Last-Modified and 304 Not Modified',
      () async {
        final cache = ClientCache();
        Map<String, String>? capturedHeaders;

        Future<http.Response> fetch([Map<String, String>? headers]) async {
          capturedHeaders = headers;
          if (headers != null &&
              headers['If-Modified-Since'] == 'Wed, 21 Oct 2015 07:28:00 GMT') {
            return http.Response('', 304);
          }
          return http.Response(
            'Modified Data',
            200,
            headers: {'last-modified': 'Wed, 21 Oct 2015 07:28:00 GMT'},
          );
        }

        final res1 = await cache.getOrFetch('https://example.com/lm', fetch);
        expect(res1.body, 'Modified Data');

        final res2 = await cache.getOrFetch('https://example.com/lm', fetch);
        expect(res2.body, 'Modified Data');
        expect(
          capturedHeaders?['If-Modified-Since'],
          'Wed, 21 Oct 2015 07:28:00 GMT',
        );
      },
    );

    test(
      'Cache-Control max-age header automatically makes entry fresh',
      () async {
        final cache = ClientCache();
        int fetchCount = 0;

        Future<http.Response> fetch([Map<String, String>? headers]) async {
          fetchCount++;
          return http.Response(
            'Max Age Data',
            200,
            headers: {'cache-control': 'public, max-age=3600'},
          );
        }

        await cache.getOrFetch('https://example.com/max-age', fetch);
        expect(fetchCount, 1);

        // Second request should serve directly from cache because max-age=3600 makes it fresh
        final res2 = await cache.getOrFetch(
          'https://example.com/max-age',
          fetch,
        );
        expect(res2.body, 'Max Age Data');
        expect(fetchCount, 1);
      },
    );
  });
}
