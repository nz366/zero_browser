// remove protocol string
import 'dart:math';
import 'package:collection/collection.dart';

String cleanUriString(String url) {
  if (url.isEmpty) return url;

  return cleanUri(Uri.parse(url));
}

String cleanUri(Uri uri) {
  if (uri.scheme.isNotEmpty) {
    return uri.toString().substring(uri.scheme.length + 3);
  }

  return uri.toString();
}

extension UriUtils on Uri {
  Uri insertOrIgnore({required String newScheme}) {
    if (scheme.isEmpty) {
      return Uri.parse("$newScheme${toString()}");
    }
    return this;
  }

  Uri resolveWithBase({required Uri? base}) {
    if (base == null) return this;
    if (host.isEmpty) {
      final newScheme = base.scheme.isEmpty ? "https" : base.scheme;
      return Uri.parse(
        "${base.host}${path.startsWith("/") ? "" : "/"}$path",
      ).insertOrIgnore(newScheme: "$newScheme://");
    }

    return this;
  }
}

const String kWildcard = '*';

List<String> uriToMatcherList(String input) {
  final hasScheme = input.contains('://');
  final uri = Uri.parse(hasScheme ? input : '//$input');

  final scheme = uri.scheme.isEmpty ? kWildcard : uri.scheme;

  final hostParts = uri.host.isEmpty
      ? [kWildcard]
      : uri.host.split('.').map((p) => p.isEmpty ? kWildcard : p).toList();

  final pathParts = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  return [scheme, ...hostParts, ...pathParts];
}

class SegmentKey {
  final List<String> segments;
  SegmentKey(this.segments);

  static const _eq = ListEquality<String>();

  @override
  bool operator ==(Object other) =>
      other is SegmentKey && _eq.equals(segments, other.segments);

  @override
  int get hashCode => _eq.hash(segments);

  @override
  String toString() => segments.join('/');
}

class UrlPatternRegistry<T> {
  final Map<SegmentKey, T> _exact = {};
  final List<MapEntry<List<String>, T>> _wildcardPatterns = [];

  void register(String pattern, T value) {
    final segments = uriToMatcherList(pattern);
    _exact[SegmentKey(segments)] = value;
    if (segments.contains(kWildcard)) {
      _wildcardPatterns.add(MapEntry(segments, value));
    }
  }

  T? match(String url) {
    final segments = uriToMatcherList(url);

    final exact = _exact[SegmentKey(segments)];
    if (exact != null) return exact;

    // 2. Wildcard scan.
    T? best;
    var bestSpecificity = -1;
    for (final entry in _wildcardPatterns) {
      if (_matches(entry.key, segments)) {
        final specificity = entry.key.where((s) => s != kWildcard).length;
        if (specificity > bestSpecificity) {
          bestSpecificity = specificity;
          best = entry.value;
        }
      }
    }
    return best;
  }

  bool _matches(List<String> pattern, List<String> input) {
    // if (pattern.length != input.length) return false;
    for (var i = 0; i < min(pattern.length, input.length); i++) {
      if (pattern[i] == kWildcard) continue;
      if (pattern[i] != input[i]) return false;
    }
    return true;
  }
}
