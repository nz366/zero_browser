// remove protocol string
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

Uri resolveWithPageUri(Uri child, Uri? parent) {
  if (parent == null) return child;
  if (child.host.isEmpty) {
    return Uri.parse(
      "${parent.scheme}:${parent.host}${child.path.startsWith("/") ? "" : "/"}${child.path}",
    );
  }

  return child;
}

extension UriUtils on Uri {
  Uri insertOrIgnore({required String sceheme}) {
    if (scheme.isEmpty) {
      return replace(scheme: sceheme);
    }
    return this;
  }
}
