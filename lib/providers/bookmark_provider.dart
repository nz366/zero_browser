import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:zero_browser/database/database.dart';

class BookmarkProvider extends ChangeNotifier {
  List<Bookmark> _bookmarks = [];
  List<Bookmark> get bookmarks => _bookmarks;

  BookmarkProvider() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    _bookmarks = await appDatabase.select(appDatabase.bookmarks).get();
    notifyListeners();
  }

  bool isBookmarked(String url) {
    return _bookmarks.any((b) => b.url == url);
  }

  Future<void> toggleBookmark(String url, {String? title}) async {
    final existing = _bookmarks.where((b) => b.url == url).toList();
    if (existing.isNotEmpty) {
      await (appDatabase.delete(appDatabase.bookmarks)..where((t) => t.id.equals(existing.first.id))).go();
    } else {
      await appDatabase.into(appDatabase.bookmarks).insert(
        BookmarksCompanion.insert(
          url: url,
          title: Value(title),
        ),
      );
    }
    await _loadBookmarks();
  }
}
