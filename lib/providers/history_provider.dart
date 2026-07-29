import 'package:drift/drift.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart'
    hide TabPaneData, TransformationController;
import 'package:uuid/uuid.dart';
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/database/database.dart';
import 'package:zero_browser/ui/tabpane.dart';
import 'package:zero_browser/model/model.dart';
import 'package:zero_browser/utils/utils.dart';
import 'package:zero_browser/widgets/browser/errors.dart';
import 'package:zero_browser/widgets/vendor/interactiveviewer.dart';

final uuid = Uuid();

class TabData {
  String id;
  bool loading = false;
  BrowserPage page;

  CancellationToken? loadToken;

  bool isRawViewMode = false;

  bool isWideMode = false;

  bool sidebarOpen = false;

  final TransformationController zoomTransformationController;
  final ScrollController scrollController;

  Client client = Client();

  TabData({
    required this.id,
    required this.page,
    TransformationController? zoomTransformationController,
    ScrollController? scrollController,
  }) : zoomTransformationController =
           zoomTransformationController ?? TransformationController(),
       scrollController = scrollController ?? ScrollController();

  final List<String> _historyController = ["browser://newtab"];

  int _historyIndex = 0;

  bool get hasBackwardHistory => _historyIndex > 0;
  bool get hasForwardHistory => _historyController.length > _historyIndex + 1;

  Future<void> visit(
    String url, {
    String? title,
    HistoryTransition? transitionType,
  }) async {
    if (!url.startsWith("browser://")) {
      await appDatabase.transaction(() async {
        final urlId = await appDatabase
            .into(appDatabase.urls)
            .insert(
              UrlsCompanion.insert(url: url, title: Value(title)),
              mode: InsertMode.insertOrIgnore,
            );

        await appDatabase
            .into(appDatabase.history)
            .insert(HistoryCompanion.insert(urlId: urlId));
      });
    }

    if (_historyController[_historyIndex] == url) {
      return;
    }

    _historyController.add(url);
    _historyIndex++;
  }

  void backward({required void Function([String? url]) onUrlChange}) {
    if (!hasBackwardHistory) {
      return;
    }
    _historyIndex--;
    onUrlChange(_historyController[_historyIndex]);
  }

  void forward({required void Function([String? url]) onUrlChange}) {
    if (!hasForwardHistory) {
      return;
    }
    _historyIndex++;
    onUrlChange(_historyController[_historyIndex]);
  }
}

enum HistoryTransition { newTab }

class TabProvider extends ChangeNotifier {
  void goBack() {
    focusedTab.backward(onUrlChange: loadTab);
  }

  void goForward() {
    focusedTab.forward(onUrlChange: loadTab);
  }

  Client client = Client();
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

  void closeTab(TabData data) {
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
    _tabs[focused].data.loading = false;
    notifyListeners();
  }

  void loadTab([String? url]) async {
    final targetTab = _tabs[focused].data;
    if (url != null) {
      targetTab.visit(url);
    }

    url = url ?? _tabs[focused].data.page.url;

    if (url == "") return;

    targetTab.page.url = url;

    targetTab.loadToken?.cancel();

    final token = CancellationToken();
    targetTab.loadToken = token;

    try {
      targetTab.loading = true;
      notifyListeners();
      final resolver = HostRegistry.resolve(url);
      final content = resolver.getContent(targetTab.client, url);
      final response = await token.run<Structure>(content);

      targetTab.page.content = response.body;
      targetTab.page.title = response.title;
    } on CancelledException catch (_) {
    } catch (e) {
      if (targetTab.loadToken != token) return;
      targetTab.page.content = [
        BrowserWidget(
          BrowserError(onRetry: () => loadTab(), error: e.toString()),
        ),
      ];
    } finally {
      targetTab.loading = false;
      notifyListeners();
    }
  }

  void branchTab(String url) {
    _tabs.add(
      TabPaneData(
        TabData(
          id: uuid.v4(),
          page: BrowserPage(
            url: url,
            title: Uri.parse(url).authority,
            content: [],
          ),
        ),
      ),
    );
    _focused = _tabs.length - 1;
    loadTab(url);
  }

  void newTab() {
    _tabs.add(
      TabPaneData(
        TabData(
          id: uuid.v4(),
          page: BrowserPage(
            url: "browser://newtab",
            title: "New Tab",
            content: [],
          ),
        ),
      ),
    );
    _focused = _tabs.length - 1;
    loadTab();
  }

  void cancelLoad() {
    final targetTab = _tabs[focused].data;
    if (targetTab.loading) {
      targetTab.loadToken?.cancel();
      targetTab.loading = false;
      notifyListeners();
    }
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

  void submitForm(BrowserPage page, FormSection form) {
    final uri = newFormUri(Uri.parse(page.url), form);
    loadTab(uri.toString());
  }

  void closeAllTabs() {
    _tabs.clear();
    newTab();
    notifyListeners();
  }

  void resetZoom() {
    Matrix4 newMatrix = Matrix4.identity();
    focusedTab.zoomTransformationController?.value = newMatrix;
    notifyListeners();
  }

  final zoomSteps = [0.5, 0.8, 1.0, 1.2, 1.4, 1.7, 2.0, 4.0];
  int zoom_index = 2;

  void zoomOut() {
    if (zoom_index > 0) {
      zoom_index--;
    }
    zoomBy(zoomSteps[zoom_index]);
  }

  void zoomIn() {
    if (zoom_index < zoomSteps.length - 1) {
      zoom_index++;
    }
    zoomBy(zoomSteps[zoom_index]);
  }

  void zoomBy(double targetScale) {
    if (targetScale == 1) {
      resetZoom();
      return;
    }

    final newMatrix = focusedTab.zoomTransformationController!.value.clone();

    newMatrix[0] = targetScale;
    newMatrix[5] = targetScale;
    newMatrix[10] = targetScale;

    focusedTab.zoomTransformationController!.value = newMatrix;
    notifyListeners();
  }

  void openTab(String tab) {}
}

Uri newFormUri(Uri uri, FormSection form) {
  final query = form.toQuery();
  uri = uri.replace(queryParameters: query);
  return uri;
}
