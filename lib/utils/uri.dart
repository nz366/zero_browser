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
