extension StringExtensions on String {
  String wrapQuostes() {
    return "\"$this\"";
  }

  String trimQuotes() {
    if (startsWith('"') && endsWith('"')) {
      return substring(1, length - 1);
    }
    return this;
  }
}
