import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide TabPane, TabPaneData;
import 'package:provider/provider.dart';

import 'package:zero_browser/providers/history_provider.dart';
import 'package:zero_browser/ui/menu.dart';
import 'package:zero_browser/ui/tabpane.dart';
import 'package:zero_browser/widgets/content.dart';
import 'package:uuid/uuid.dart';
import 'package:zero_browser/providers/bookmark_provider.dart';

final uuid = Uuid();

// PageData is now imported from model/data.dart

class TabPaneProviderExample extends StatelessWidget {
  const TabPaneProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the provider state
    final provider = context.watch<TabProvider>();
    final tabs = provider.tabs;
    final focused = provider.focused;
    final focusedTab = provider.focusedTab;
    return TabPane<TabData>(
      items: tabs,
      focused: focused,
      onFocused: (value) => provider.setFocused(value),
      onSort: (value) => provider.updateTabs(value),
      onAdd: () => provider.newTab(),
      barHeight: 35,

      // Header item builder
      itemBuilder: (context, item, index) {
        final data = item.data;
        return TabItem(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 200, minWidth: 180),
            child: Tooltip(
              tooltip: (c) => TooltipContainer(child: Text(data.page.title)),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Label(
                  leading: _buildBadge(context, data),
                  trailing: focused != index
                      ? null
                      : IconButton.ghost(
                          shape: ButtonShape.circle,
                          size: ButtonSize.xSmall,
                          icon: const Icon(Icons.close),
                          onPressed: () => provider.removeTab(data),
                        ),
                  child: Text(data.page.title, maxLines: 1),
                ),
              ),
            ),
          ),
        );
      },

      // Global Tab Actions
      leading: [
        IconButton.secondary(
          icon: const Icon(Icons.arrow_drop_down),
          size: ButtonSize.small,
          onPressed: () {},
        ),
      ],
      trailing: [],

      // Content Area
      child: Column(
        children: [
          Row(
            children: [
              IconButton.ghost(
                icon: Icon(Icons.arrow_back),
                onPressed: provider.focusedTab.backHistory.isNotEmpty
                    ? () => provider.goBack()
                    : null,
              ),
              IconButton.ghost(
                icon: Icon(Icons.arrow_forward),
                onPressed: provider.focusedTab.forwardHistory.isNotEmpty
                    ? () => provider.goForward()
                    : null,
              ),
              IconButton.ghost(
                icon: provider.focusedTab.page.loading
                    ? Icon(Icons.close)
                    : Icon(Icons.refresh),
                onPressed: () {
                  if (provider.focusedTab.page.loading) {
                    provider.cancelLoad();
                  } else {
                    provider.loadTab();
                  }
                },
              ),

              Spacer(),
              Consumer<BookmarkProvider>(
                builder: (context, bookmarkProvider, _) {
                  final isBookmarked = bookmarkProvider.isBookmarked(
                    focusedTab.page.url,
                  );
                  return IconButton.ghost(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    ),
                    onPressed: () {
                      bookmarkProvider.toggleBookmark(
                        focusedTab.page.url,
                        title: focusedTab.page.title,
                      );
                    },
                  );
                },
              ),

              // IconButton.ghost(icon: Icon(Icons.share), onPressed: () {}),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: .symmetric(horizontal: 10, vertical: 4),
                  child: TextField(
                    onChanged: (e) {
                      focusedTab.page.url = e;
                    },
                    placeholder: Text('Type to search or url'),
                    onSubmitted: (e) => provider.navigateWithHistory(e),
                    controller: TextEditingController(
                      text: focusedTab.page.url,
                    ),

                    features: [
                      InputFeature.leading(
                        GestureDetector(
                          child: Icon(LucideIcons.settings2),
                          onTap: () {
                            showBrowserTabSettings(context);
                          },
                        ),
                      ),

                      // InputFeature.trailing(
                      //   IconButton.ghost(
                      //     icon: Icon(Icons.visibility),
                      //     onPressed: () {
                      //       provider.toggleViewMode();
                      //     },
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),

              Spacer(),

              IconButton.ghost(
                icon: Icon(LucideIcons.menu),
                onPressed: () {
                  showBrowserTabSettings(context);
                },
              ),
            ],
          ),

          Divider(),

          Expanded(
            child: Center(
              child: tabs.isEmpty
                  ? const Text("No tabs open")
                  : tabs[focused].data.isRawViewMode
                  ? Text(tabs[focused].data.page.toString())
                  : Flex(
                      // TODO: vertical on mobile?
                      direction: Axis.horizontal,
                      children: [
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: tabs[focused].data.isWideMode
                                  ? const BoxConstraints()
                                  : const BoxConstraints(maxWidth: 1000),
                              child: ContentView(
                                page: provider.focusedTab.page,
                              ),
                            ),
                          ),
                        ),
                        if (provider.focusedTab.sidebarOpen)
                          Flexible(flex: 0, child: VerticalDivider()),

                        if (provider.focusedTab.sidebarOpen)
                          buildSource(provider, tabs, focused),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildToast(BuildContext context, ToastOverlay overlay) {
    return SurfaceCard(
      child: Basic(
        title: const Text('Copied to Clipboard'),
        trailing: PrimaryButton(
          size: ButtonSize.small,
          onPressed: () {
            overlay.close();
          },
          child: const Text('Close'),
        ),
        trailingAlignment: Alignment.center,
      ),
    );
  }

  Expanded buildSource(
    TabProvider provider,
    List<TabPaneData<TabData>> tabs,
    int focused,
  ) {
    return Expanded(
      child: Card(
        child: Builder(
          builder: (context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Spacer(),
                    IconButton.ghost(
                      icon: Icon(Icons.file_copy_outlined),
                      // icon: Icon(Icons.account_box),
                      onPressed: () async {
                        final data = tabs[focused].data.page.content
                            .map((e) => e.toJson())
                            .join("\n");
                        await Clipboard.setData(ClipboardData(text: data));

                        showToast(
                          context: context,
                          builder: buildToast,
                          // Position top-right.
                          location: ToastLocation.topRight,
                        );
                      },
                    ),

                    IconButton.ghost(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        provider.toggleTabSidebar();
                      },
                    ),
                  ],
                ),

                Gap(10),

                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: tabs[focused].data.isWideMode
                            ? const BoxConstraints()
                            : const BoxConstraints(maxWidth: 1000),
                        child: CodeSnippet(
                          code: Text(
                            provider.focusedTab.page.content
                                .map((e) => e.toJson())
                                .join("\n"),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // child: Text(
      //   provider.focusedTab.page.toString(),
      // ),
    );
  }

  Widget _buildBadge(BuildContext context, TabData data) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Builder(
        builder: (c) {
          if (data.page.loading) return CircularProgressIndicator();
          return Icon(LucideIcons.globe, size: 16);
        },
      ),
    );
  }
}
