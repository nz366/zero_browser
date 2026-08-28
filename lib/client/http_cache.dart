import 'package:http/http.dart';

class CacheEntry {
  final Response response;
  final DateTime timestamp;
  final String? etag;
  final String? lastModified;
  final Duration? maxAge;

  CacheEntry(this.response, this.timestamp)
    : etag = _parseEtag(response.headers),
      lastModified = _parseLastModified(response.headers),
      maxAge = _parseMaxAge(response.headers);

  static String? _parseEtag(Map<String, String> headers) {
    return headers['etag'] ?? headers['ETag'];
  }

  static String? _parseLastModified(Map<String, String> headers) {
    return headers['last-modified'] ?? headers['Last-Modified'];
  }

  static Duration? _parseMaxAge(Map<String, String> headers) {
    final cacheControl = headers['cache-control'] ?? headers['Cache-Control'];
    if (cacheControl == null) return null;
    final match = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
    if (match != null) {
      final seconds = int.tryParse(match.group(1)!);
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    }
    return null;
  }

  bool isFresh(Duration? maxAgeOverride) {
    final effectiveMaxAge = maxAgeOverride ?? maxAge;
    if (effectiveMaxAge != null) {
      return DateTime.now().difference(timestamp) <= effectiveMaxAge;
    }
    // If no maxAge or Cache-Control header is given, and entry has validation info (ETag or Last-Modified), treat as needing revalidation
    if (etag != null || lastModified != null) {
      return false;
    }
    return true;
  }
}

typedef FetchCallback =
    Future<Response> Function([Map<String, String>? headers]);

class ClientCache {
  final Map<String, CacheEntry> _cache = {};
  final Map<String, Future<Response>> _pendingRequests = {};

  Response? get(dynamic key) => _cache[key.toString()]?.response;

  String? getString(dynamic key) => get(key)?.body;

  void set(dynamic key, Response response) {
    _cache[key.toString()] = CacheEntry(response, DateTime.now());
  }

  bool containsKey(dynamic key) => _cache.containsKey(key.toString());

  void remove(dynamic key) {
    _cache.remove(key.toString());
  }

  void invalidate(dynamic key) => remove(key);

  void invalidateWhere(bool Function(String key, Response response) test) {
    _cache.removeWhere((key, entry) => test(key, entry.response));
  }

  void clear() {
    _cache.clear();
    _pendingRequests.clear();
  }

  Future<Response> getOrFetch(
    dynamic key,
    Function fetchFn, {
    Duration? maxAge,
    bool forceRefresh = false,
  }) async {
    final keyStr = key.toString();
    final cachedEntry = _cache[keyStr];

    if (!forceRefresh && cachedEntry != null) {
      if (cachedEntry.isFresh(maxAge)) {
        return cachedEntry.response;
      }
    }

    final pending = _pendingRequests[keyStr];
    if (pending != null) {
      return pending;
    }

    Map<String, String>? validationHeaders;
    if (!forceRefresh && cachedEntry != null) {
      validationHeaders = {};
      if (cachedEntry.etag != null) {
        validationHeaders['If-None-Match'] = cachedEntry.etag!;
      }
      if (cachedEntry.lastModified != null) {
        validationHeaders['If-Modified-Since'] = cachedEntry.lastModified!;
      }
      if (validationHeaders.isEmpty) {
        validationHeaders = null;
      }
    }

    final Future<Response> future;
    if (fetchFn is FetchCallback) {
      future = fetchFn(validationHeaders);
    } else {
      Future<Response>? f;
      try {
        f = (fetchFn as dynamic)(validationHeaders) as Future<Response>?;
      } on NoSuchMethodError {
        // Fallback for zero-argument functions
      } catch (_) {
        // Other errors fallback
      }
      future = f ?? ((fetchFn as dynamic)() as Future<Response>);
    }
    _pendingRequests[keyStr] = future;

    try {
      final result = await future;
      if (result.statusCode == 304 && cachedEntry != null) {
        // Resource unchanged, refresh cache timestamp & return cached entry
        final updatedEntry = CacheEntry(cachedEntry.response, DateTime.now());
        _cache[keyStr] = updatedEntry;
        return cachedEntry.response;
      } else if (result.statusCode == 200) {
        _cache[keyStr] = CacheEntry(result, DateTime.now());
      }
      return result;
    } finally {
      _pendingRequests.remove(keyStr);
    }
  }
}
