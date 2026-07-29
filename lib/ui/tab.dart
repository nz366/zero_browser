import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart'
    hide TabPane, TabPaneData, InteractiveViewer;
import 'package:provider/provider.dart';
import 'package:zero_browser/providers/history_provider.dart';

import 'package:zero_browser/ui/menu.dart';
import 'package:zero_browser/ui/sitemenu.dart';
import 'package:zero_browser/ui/tablist.dart';
import 'package:zero_browser/ui/tabpane.dart';
import 'package:zero_browser/widgets/content.dart';
import 'package:zero_browser/providers/bookmark_provider.dart';
import 'package:zero_browser/widgets/density.dart';
import 'package:zero_browser/widgets/vendor/interactiveviewer.dart';

class TabPaneWidget extends StatelessWidget {
  const TabPaneWidget({super.key});

  @override
  Widget build(BuildContext context) {
    Color? TabBG = Theme.of(context).colorScheme.background.withLuminance(
      Theme.of(context).brightness == Brightness.light ? .95 : .12,
    );

    // Access the provider state
    final provider = context.watch<TabProvider>();
    final tabs = provider.tabs;
    final focused = provider.focused;
    final focusedTab = provider.focusedTab;

    return TabPane<TabData>(
      tabHandleColor: TabBG,
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
                child: FadedOverlay(
                  leading: SizedBox(
                    width: 20,
                    height: 20,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: data.loading
                          ? const CircularProgressIndicator(
                              key: ValueKey('loading'),
                            )
                          : const Icon(
                              LucideIcons.globe,
                              size: 16,
                              key: ValueKey('icon'),
                            ),
                    ),
                  ),
                  trailing: focused != index
                      ? null
                      : IconButton.ghost(
                          shape: ButtonShape.circle,
                          size: ButtonSize.xSmall,
                          icon: const Icon(Icons.close),
                          onPressed: () => provider.closeTab(data),
                        ),
                  child: Text(data.page.title.split("://").last),
                ),
              ),
            ),
          ),
        );
      },

      // Global Tab Actions
      leading: [
        OverlayAnchor(
          anchor: browserTabListPopUp,
          child: IconButton.secondary(
            icon: const Icon(Icons.arrow_drop_down),
            size: ButtonSize.small,
            onPressed: () {
              showTabListPopUp(context);
            },
          ),
        ),
      ],
      trailing: [],

      // Content Area
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: TabBG),
            child: Row(
              children: [
                IconButton.ghost(
                  icon: Icon(Icons.arrow_back),
                  onPressed: provider.focusedTab.hasBackwardHistory
                      ? () => provider.goBack()
                      : null,
                ),
                IconButton.ghost(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: provider.focusedTab.hasForwardHistory
                      ? () => provider.goForward()
                      : null,
                ),
                IconButton.ghost(
                  icon: provider.focusedTab.loading
                      ? Icon(Icons.close)
                      : Icon(Icons.refresh),
                  onPressed: () {
                    if (provider.focusedTab.loading) {
                      provider.cancelLoad();
                    } else {
                      provider.loadTab();
                    }
                  },
                ),

                Spacer(),

                // IconButton.ghost(icon: Icon(Icons.share), onPressed: () {}),
                Expanded(
                  flex: 3,
                  child: DowngradeDensity(
                    child: Padding(
                      padding: .symmetric(horizontal: 10, vertical: 4),
                      child: TextField(
                        onChanged: (e) {
                          focusedTab.page.url = e;
                        },
                        placeholder: Text('Type to search or url'),
                        onSubmitted: (e) => provider.loadTab(e),
                        controller: TextEditingController(
                          text: focusedTab.page.url,
                        ),

                        features: [
                          InputFeature.leading(
                            OverlayAnchor(
                              anchor: sitemenuSymbol,
                              child: IconButton.ghost(
                                icon: Icon(LucideIcons.settings2),
                                onPressed: () {
                                  showSiteMenu(context);
                                },
                              ),
                            ),
                          ),

                          InputFeature.trailing(
                            Consumer<BookmarkProvider>(
                              builder: (context, bookmarkProvider, _) {
                                final isBookmarked = bookmarkProvider
                                    .isBookmarked(focusedTab.page.url);
                                return IconButton.outline(
                                  icon: Icon(
                                    isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_outline,
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Spacer(),

                OverlayAnchor(
                  anchor: browserMenuLayerLink,
                  child: IconButton.ghost(
                    icon: Icon(LucideIcons.menu),
                    onPressed: () {
                      showBrowserTabSettings(context);
                    },
                  ),
                ),
              ],
            ),
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
                        Expanded(child: ContentArea()),
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
                      onPressed: () async {
                        final data = JsonEncoder.withIndent(
                          '  ',
                        ).convert(tabs[focused].data.page.toJson());
                        await Clipboard.setData(ClipboardData(text: data));

                        showToast(
                          context: context,
                          builder: buildToast,
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

                Expanded(child: SourcePanel()),
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
}

class BrowserInteractiveViewer extends StatelessWidget {
  final Widget child;

  const BrowserInteractiveViewer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TabProvider>();
    return InteractiveViewer(
      minScale: 0.5,
      transformationController:
          provider.focusedTab.zoomTransformationController,
      child: child,
    );
  }
}

class ContentArea extends StatefulWidget {
  const ContentArea({super.key});

  @override
  State<ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<ContentArea> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TabProvider>();

    return BrowserInteractiveViewer(
      child: Scrollbar(
        controller: provider.focusedTab.scrollController,
        thickness: 8,
        trackVisibility: true,
        thumbVisibility: true,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: provider.focusedTab.isWideMode
                ? BoxConstraints(maxWidth: MediaQuery.of(context).size.width)
                : const BoxConstraints(maxWidth: 1000),
            child: ContentView(
              page: provider.focusedTab.page,
              scrollController: provider.focusedTab.scrollController,
            ),
          ),
        ),
      ),
    );
  }
}

class FadedOverlay extends StatelessWidget {
  final Widget leading;
  final Widget? trailing;
  final Widget child;

  const FadedOverlay({
    super.key,
    required this.leading,
    required this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: .centerStart,
      children: [
        SizedBox(
          width: 300,
          child: Row(
            children: [
              leading,
              Gap(4),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.black, Colors.black, Colors.transparent],
                      stops: trailing == null
                          ? const [0.0, 0.95, 1.0]
                          : const [0.0, 0.75, 0.9],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: child,
                ),
              ),
            ],
          ),
        ),

        Positioned(right: 0, child: trailing ?? SizedBox.shrink()),
      ],
    );
  }
}
