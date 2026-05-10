import 'package:flutter/foundation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide TabPaneData;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';
import 'package:zero_browser/ui/tab.dart';
import 'package:zero_browser/ui/tabpane.dart';
import 'package:zero_browser/utils/cancel_token.dart';

class LinkedHistory {
  final String url;
  final String title;
  final DateTime dateTime;

  final LinkedHistory parent;
  List<LinkedHistory> children = [];

  LinkedHistory({
    required this.parent,
    required this.url,
    required this.title,
    required this.dateTime,
  });

  void visit(String url, String title) {
    LinkedHistory next = LinkedHistory(
      url: url,
      title: title,
      dateTime: DateTime.now(),
      parent: this,
    );

    children.add(next);
  }
}

class TabData {
  late final String id;
  PageData page;

  List<String> backHistory = [];
  List<String> forwardHistory = [];
  String? currentHistoryUrl;

  // Controls cancellation for ongoing loads, wrapping the future in Future.any
  CancellationToken? loadToken;

  bool isRawViewMode = false;

  bool isWideMode = false;

  bool sidebarOpen = false;
  TabData({required this.page}) {
    id = uuid.v4();
    currentHistoryUrl = page.url;
  }

  void addHistory(String url) {
    if (currentHistoryUrl != null && currentHistoryUrl != url) {
      backHistory.add(currentHistoryUrl!);
      forwardHistory.clear();
    }
  }
}

class TabProvider extends ChangeNotifier {
  List<TabPaneData<TabData>> _tabs = [];
  int _focused = 0;

  List<TabPaneData<TabData>> get tabs => _tabs;
  int get focused => _focused;

  TabProvider() {
    newTab();
  }

  TabData get focusedTab => _tabs[focused].data;

  void setFocused(int index) {
    _focused = index;
    notifyListeners();
  }

  void updateTabs(List<TabPaneData<TabData>> newTabs) {
    _tabs = newTabs;
    notifyListeners();
  }

  void newTab() {
    openTab("browser:newtab");
    _focused = _tabs.length - 1; // Auto-focus new tab
    notifyListeners();
  }

  void goBack() {
    final targetTab = _tabs[focused].data;
    if (targetTab.backHistory.isNotEmpty) {
      targetTab.forwardHistory.add(
        targetTab.currentHistoryUrl ?? targetTab.page.url,
      );
      final prevUrl = targetTab.backHistory.removeLast();
      loadTab(prevUrl);
    }
  }

  void goForward() {
    final targetTab = _tabs[focused].data;
    if (targetTab.forwardHistory.isNotEmpty) {
      targetTab.backHistory.add(
        targetTab.currentHistoryUrl ?? targetTab.page.url,
      );
      final nextUrl = targetTab.forwardHistory.removeLast();
      loadTab(nextUrl);
    }
  }

  void removeTab(TabData data) {
    _tabs.removeWhere((element) => element.data.id == data.id);
    // Ensure focused index stays within bounds
    if (_focused >= _tabs.length && _tabs.isNotEmpty) {
      _focused = _tabs.length - 1;
    }

    if (_tabs.isEmpty) {
      newTab();
    }
    notifyListeners();
  }

  void cancelLoading() {
    _tabs[focused].data.page.loading = false;
    notifyListeners();
  }

  void navigateWithHistory([String? url]) {
    String destination = url ?? focusedTab.page.url.toString();
    focusedTab.addHistory(destination);
    loadTab(destination);
  }

  void loadTab([String? url]) async {
    url = url ?? _tabs[focused].data.page.url;

    if (url == "") return;

    final targetTab = _tabs[focused].data;

    targetTab.currentHistoryUrl = url;
    targetTab.page.url = url;

    // Cancel the previous token if there is an ongoing load
    targetTab.loadToken?.cancel();

    final token = CancellationToken();
    targetTab.loadToken = token;

    try {
      final data = fetchData(targetTab, url);
      targetTab.page.loading = true;
      notifyListeners();

      // We run the future through the token to exit out of the await
      // immediately when CancelledException is thrown durlng cancel()
      final response = await token.run<DataResponse?>(data);

      if (response == null) return;

      targetTab.page.content = response.body;
      targetTab.page.title = response.title;
      targetTab.page.loading = false;

      notifyListeners();
    } on CancelledException catch (_) {
      // Intentionally do nothing and let the new load take over, or just exit.
    } catch (e) {
      if (targetTab.loadToken != token) return; // Ignore if overwritten

      targetTab.page.content = [MarkdownSection(e.toString())];
      targetTab.page.loading = false;
      notifyListeners();
    }
  }

  void cancelLoad() {
    final targetTab = _tabs[focused].data;
    if (targetTab.page.loading) {
      targetTab.loadToken?.cancel();
      targetTab.page.loading = false;
      notifyListeners();
    }
  }

  void openTab(String url) {
    _tabs.add(
      TabPaneData(
        TabData(
          page: PageData(url: url, title: url, content: []),
        ),
      ),
    );
    _focused = _tabs.length - 1;
    loadTab(url);
  }

  void toggleViewMode() {
    _tabs[_focused].data.isRawViewMode = !_tabs[focused].data.isRawViewMode;
    notifyListeners();
  }

  void toggleWideMode() {
    _tabs[_focused].data.isWideMode = !_tabs[focused].data.isWideMode;
    notifyListeners();
  }

  void toggleTabSidebar() {
    focusedTab.sidebarOpen = !focusedTab.sidebarOpen;

    notifyListeners();
  }

  void submitForm(PageData page, FormSection form) {
    final uri = newFormUri(Uri.parse(page.url), form);
    navigateWithHistory(uri.toString());
  }
}

Uri newFormUri(Uri uri, FormSection form) {
  final query = form.toQuery();
  uri = uri.replace(queryParameters: query);
  return uri;
}
