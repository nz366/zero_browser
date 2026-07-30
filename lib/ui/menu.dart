import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/providers/history_provider.dart';
import 'package:zero_browser/providers/theme_provider.dart' show ThemeProvider;

final Symbol browserMenuLayerLink = #browserMenuLayerLink;
void showBrowserTabSettings(BuildContext context) {
  showPopover(
    anchor: browserMenuLayerLink,
    alignment: Alignment.topCenter,
    builder: (context) => const BrowserMenuPopover(),
  );
}

class BrowserMenuPopover extends StatefulWidget {
  const BrowserMenuPopover({super.key});

  @override
  State<BrowserMenuPopover> createState() => _BrowserMenuPopoverState();
}

class _BrowserMenuPopoverState extends State<BrowserMenuPopover> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TabProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.accent.withOpacity(.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Theme.of(context).colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 320, maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),

              const Divider(height: 24),

              _buildMenuAction(
                context,
                icon: LucideIcons.plus,
                label: "New Tab",
                shortcut: "Ctrl+T",
                onPressed: () {
                  provider.newTab();
                  closeOverlay(context);
                },
              ),

              const Divider(height: 24),

              _buildTabButton(
                provider,
                context,
                icon: LucideIcons.history,
                label: "History",
                tab: "browser://history",
              ),

              _buildTabButton(
                provider,
                context,
                icon: LucideIcons.pin,
                label: "Pinned",
                tab: "browser://pinned",
              ),

              _buildTabButton(
                provider,
                context,
                icon: LucideIcons.star,
                label: "Bookmarks",
                tab: "browser://bookmarks",
              ),

              const Divider(height: 24),

              _buildZoomRow(),

              const Divider(height: 24),

              _buildMenuAction(
                context,
                icon: LucideIcons.search,
                label: "Find",
                shortcut: "Ctrl+F",
                onPressed: () {},
              ),

              const Divider(height: 24),

              _buildTabButton(
                provider,
                context,
                icon: LucideIcons.settings,
                label: "Settings",
                tab: "browser://settings",
              ),

              _buildMenuAction(
                context,
                icon: LucideIcons.code,
                label: "View Source",
                onPressed: () {
                  provider.toggleTabSidebar();
                  closeOverlay(context);
                },
              ),

              _buildMenuAction(
                context,
                icon: LucideIcons.circleHelp,
                label: "Help",
                onPressed: () {},
              ),

              _buildMenuAction(
                context,
                icon: LucideIcons.info,
                label: "About",
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Consumer<ThemeProvider>(
          builder: (_, theme, _) {
            return IconButton.ghost(
              size: ButtonSize.small,
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? LucideIcons.sun
                    : LucideIcons.moon,
              ),
              onPressed: theme.toggleBrightNess,
            );
          },
        ),

        const Gap(8),

        Consumer<TabProvider>(
          builder: (_, provider, _) {
            return IconButton.ghost(
              size: ButtonSize.small,
              icon: Icon(
                provider.focusedTab.isWideMode
                    ? LucideIcons.unfoldHorizontal
                    : LucideIcons.foldHorizontal,
              ),
              onPressed: provider.toggleWideMode,
            );
          },
        ),
      ],
    );
  }

  Widget _buildZoomRow() {
    return Row(
      children: [
        Text(
          "Zoom",
          style: Theme.of(context).typography.base.copyWith(fontSize: 13),
        ),
        const Spacer(),
        IconButton.ghost(
          size: ButtonSize.small,
          icon: const Icon(LucideIcons.minus),
          onPressed: () {
            Provider.of<TabProvider>(context, listen: false).zoomOut();
          },
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Consumer<TabProvider>(
            builder: (context, provider, _) {
              final zval = provider
                  .focusedTab
                  .zoomTransformationController
                  .value
                  .getMaxScaleOnAxis();
              return Text("${(zval * 100.0).toStringAsFixed(0)}%");
            },
          ),
        ),
        IconButton.ghost(
          size: ButtonSize.small,
          icon: const Icon(LucideIcons.plus),
          onPressed: () {
            Provider.of<TabProvider>(context, listen: false).zoomIn();
          },
        ),
        const Gap(8),
        IconButton.ghost(
          size: ButtonSize.small,
          icon: const Icon(LucideIcons.maximize),
          onPressed: () {
            Provider.of<TabProvider>(context, listen: false).resetZoom();
          },
        ),
      ],
    );
  }

  Widget _buildTabButton(
    TabProvider provider,
    BuildContext context, {
    required IconData icon,
    required String label,
    required String tab,
  }) {
    return _buildMenuAction(
      context,
      icon: icon,
      label: label,
      onPressed: () {
        provider.branchTab(tab);
        closeOverlay(context);
      },
    );
  }

  Widget _buildMenuAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? shortcut,
    required VoidCallback onPressed,
  }) {
    return Button.ghost(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const Gap(12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).typography.base.copyWith(fontSize: 13),
              ),
            ),
            if (shortcut != null)
              Text(
                shortcut,
                style: Theme.of(
                  context,
                ).typography.xSmall.copyWith(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
