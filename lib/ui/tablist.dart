import 'package:flutter/material.dart' show InkWell;
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/providers/history_provider.dart';

final Symbol browserTabListPopUp = #browserTabListPopUp;

void showTabListPopUp(BuildContext context) {
  showPopover(
    anchor: browserTabListPopUp,
    alignment: Alignment.topCenter,
    builder: (context) {
      return const SearchTabsWidget();
    },
  );
}

class SearchTabsWidget extends StatefulWidget {
  const SearchTabsWidget({super.key});

  @override
  State<SearchTabsWidget> createState() => _SearchTabsWidgetState();
}

class _SearchTabsWidgetState extends State<SearchTabsWidget> {
  final TextEditingController _controller = TextEditingController();
  String _query = "";

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TabProvider>(context);
    final tabs = provider.tabs;

    final filteredTabs = tabs.where((tab) {
      final title = tab.data.page.title.toLowerCase();
      final url = tab.data.page.url.toLowerCase();
      final q = _query.toLowerCase();

      return title.contains(q) || url.contains(q);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border.all(color: Theme.of(context).colorScheme.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.accent.withValues(alpha: .2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 340,
          maxWidth: 380,
          maxHeight: 450,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              features: [InputFeature.clear()],

              controller: _controller,
              onChanged: (value) {
                setState(() => _query = value);
              },
              // decoration: const InputDecoration(
              //   hintText: "Search tabs...",
              //   prefixIcon: Icon(LucideIcons.search, size: 18),
              //   isDense: true,
              // ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Text(
                  "${filteredTabs.length} Tabs",
                  style: Theme.of(
                    context,
                  ).typography.medium.copyWith(fontSize: 13),
                ),
                const Spacer(),
                Button.ghost(
                  onPressed: tabs.isEmpty
                      ? null
                      : () {
                          provider.closeAllTabs();
                        },
                  child: const Text("Clear All"),
                ),
              ],
            ),

            const Divider(height: 20),

            Expanded(
              child: filteredTabs.isEmpty
                  ? Center(
                      child: Text(
                        "No matching tabs",
                        style: Theme.of(context).typography.small,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredTabs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tab = filteredTabs[index];
                        final uri = Uri.tryParse(tab.data.page.url);

                        return InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            provider.setFocused(index);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  uri?.scheme == "https"
                                      ? LucideIcons.lock
                                      : LucideIcons.globe,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tab.data.page.title.isEmpty
                                            ? "Untitled"
                                            : tab.data.page.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).typography.medium,
                                      ),
                                      Text(
                                        tab.data.page.url,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .typography
                                            .xSmall
                                            .copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
