import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/providers/history_provider.dart';
import 'package:zero_browser/ui/theme_provider.dart';

void showBrowserTabSettings(BuildContext context) {
  showPopover(
    position: Offset(0, 100),
    alignment: Alignment.topRight,
    context: context,
    // expands: true,
    builder: (context) {
      final provider = Provider.of<TabProvider>(context, listen: false);
      return Container(
        margin: EdgeInsets.only(top: 100, right: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.accent,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: Theme.of(context).colorScheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // // Search/Title
                // const Padding(
                //   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                //   child: Text(
                //     "Menu",
                //     style: TextStyle(
                //       fontSize: 18,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
                // const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Gap(8),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return IconButton.ghost(
                            icon: Icon(
                              themeProvider.isDark
                                  ? LucideIcons.sun
                                  : LucideIcons.moon,
                            ),
                            size: ButtonSize.small,
                            onPressed: () => themeProvider.toggle(),
                          );
                        },
                      ),

                      const Gap(8),
                      Consumer<TabProvider>(
                        builder: (context, provider, _) {
                          return IconButton.ghost(
                            icon: Icon(
                              provider.focusedTab.isWideMode
                                  ? LucideIcons.unfoldHorizontal
                                  : LucideIcons.foldHorizontal,
                            ),
                            size: ButtonSize.small,
                            onPressed: () => provider.toggleWideMode(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(),
                // Quick Actions
                MenuAction(
                  icon: LucideIcons.plus,
                  label: "New Tab",
                  shortcut: "Ctrl+T",
                  onPressed: () {
                    context.read<TabProvider>().newTab();
                    closeOverlay(context);
                  },
                ),
                // MenuAction(
                //   icon: LucideIcons.copy,
                //   label: "New",
                //   shortcut: "Ctrl+N",
                //   onPressed: () {},
                // ),

                // MenuAction(
                //   icon: LucideIcons.shield,
                //   label: "New Incognito Window",
                //   shortcut: "Ctrl+Shift+N",
                //   onPressed: () {},
                // ),
                const Divider(),

                // Navigation History
                buildTabOpenButton(
                  provider,
                  context,
                  tab: "browser:history",
                  icon: LucideIcons.history,
                  label: "History",
                ),
                buildTabOpenButton(
                  provider,
                  context,
                  tab: "browser:pinned",
                  icon: LucideIcons.pin,
                  label: "Pinned",
                ),
                buildTabOpenButton(
                  provider,
                  context,
                  tab: "browser:bookmarks",
                  icon: LucideIcons.star,
                  label: "Bookmarks",
                ),

                Divider(),

                // Zoom Controls
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Text("Zoom"),
                      const Spacer(),
                      IconButton.ghost(
                        icon: const Icon(LucideIcons.minus),
                        size: ButtonSize.small,
                        onPressed: () {},
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("100%"),
                      ),
                      IconButton.ghost(
                        icon: const Icon(LucideIcons.plus),
                        size: ButtonSize.small,
                        onPressed: () {},
                      ),
                      const Gap(8),
                      IconButton.ghost(
                        icon: const Icon(LucideIcons.maximize),
                        size: ButtonSize.small,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const Divider(),

                MenuAction(
                  icon: LucideIcons.search,
                  label: "Find",
                  shortcut: "Ctrl+F",
                  onPressed: () {},
                ),

                const Divider(),

                // Global Actions
                buildTabOpenButton(
                  provider,
                  context,
                  tab: "browser:settings",
                  icon: LucideIcons.settings,
                  label: "Settings",
                ),

                MenuAction(
                  icon: LucideIcons.code,
                  label: "View Source",
                  onPressed: () => toggleTabSidebar(provider, context),
                ),
                MenuAction(
                  icon: LucideIcons.circleHelp,
                  label: "Help",
                  onPressed: () {},
                ),
                MenuAction(
                  icon: LucideIcons.info,
                  label: "About Zero Browser",
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void toggleTabSidebar(TabProvider provider, BuildContext context) {
  provider.toggleTabSidebar();
  closeOverlay(context);
}

MenuAction buildTabOpenButton(
  TabProvider provider,
  BuildContext context, {
  required IconData icon,
  required String label,
  required String tab,
}) {
  return MenuAction(
    icon: icon,
    label: label,
    onPressed: () {
      provider.openTab(tab);
      closeOverlay(context);
    },
  );
}

class MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? shortcut;
  final VoidCallback onPressed;

  const MenuAction({
    required this.icon,
    required this.label,
    this.shortcut,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button.ghost(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const Gap(12),
            Expanded(child: Text(label)),
            if (shortcut != null)
              Text(
                shortcut!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.mutedForeground,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
