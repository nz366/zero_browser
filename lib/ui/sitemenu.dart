import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/providers/history_provider.dart';

final Symbol sitemenuSymbol = #sitemenuLayerLink;

void showSiteMenu(BuildContext context) {
  showPopover(
    anchor: sitemenuSymbol,
    alignment: Alignment.topCenter,
    builder: (context) {
      return const SiteSettingsPopover();
    },
  );
}

class SiteSettingsPopover extends StatefulWidget {
  const SiteSettingsPopover({super.key});

  @override
  State<SiteSettingsPopover> createState() => _SiteSettingsPopoverState();
}

class _SiteSettingsPopoverState extends State<SiteSettingsPopover> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TabProvider>(context, listen: false);
    final focusedTab = provider.focusedTab;
    final page = focusedTab.page;
    final uri = Uri.tryParse(page.url);
    final domain = uri != null && uri.host.isNotEmpty ? uri.host : page.url;
    IconData secureIcon = LucideIcons.info;
    String secureText = "Connection is not secure";
    Color secureColor = Colors.orange;
    switch (uri?.scheme) {
      case "http":
        secureIcon = LucideIcons.lockOpen;
        secureText = "Connection is not secure";
        secureColor = Colors.orange;
        break;
      case "https":
        secureIcon = LucideIcons.lock;
        secureText = "Connection is secure";
        secureColor = Colors.green;
        break;
      case "browser":
        secureIcon = LucideIcons.info;
        secureText = "Browser Response";
        secureColor = Colors.gray;
        break;
      case "file":
        secureIcon = LucideIcons.fileCode;
        secureText = "Local system file";
        secureColor = Colors.gray;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.accent.withOpacity(0.2),
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
              // Security status header
              Row(
                children: [
                  Icon(secureIcon, color: secureColor, size: 18),
                  const Gap(8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain,
                          style: Theme.of(
                            context,
                          ).typography.medium.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          secureText,
                          style: Theme.of(
                            context,
                          ).typography.xSmall.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // // Permissions section
              // Text(
              //   "Permissions",
              //   style: Theme.of(
              //     context,
              //   ).typography.semiBold.copyWith(fontSize: 13),
              // ),
              // const Gap(10),
              // _buildPermissionRow(
              //   "Location",
              //   LucideIcons.mapPin,
              //   _locationAllowed,
              //   (v) {
              //     setState(() => _locationAllowed = v);
              //   },
              // ),
              const Divider(height: 24),

              // // Cookies & Data
              // Row(
              //   children: [
              //     const Icon(LucideIcons.cookie, size: 16),
              //     const Gap(8),
              //     // Expanded(
              //     //   child: Text(
              //     //     "$_cookiesCount cookies in use",
              //     //     style: Theme.of(
              //     //       context,
              //     //     ).typography.base.copyWith(fontSize: 13),
              //     //   ),
              //     // ),
              //     Button.ghost(
              //       // size: ButtonSize.xSmall,
              //       onPressed: _cookiesCount == 0
              //           ? null
              //           : () {
              //               setState(() => _cookiesCount = 0);
              //               showToast(
              //                 context: context,
              //                 builder: (context, overlay) => SurfaceCard(
              //                   child: Basic(
              //                     title: const Text(
              //                       'Cookies cleared for this site',
              //                     ),
              //                     trailing: PrimaryButton(
              //                       size: ButtonSize.small,
              //                       onPressed: () => overlay.close(),
              //                       child: const Text('OK'),
              //                     ),
              //                   ),
              //                 ),
              //               );
              //             },
              //       child: const Text("Clear"),
              //     ),
              //   ],
              // ),
              const Gap(8),

              // Cache & Storage
              buildInfoRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Row buildInfoRow(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.hardDrive, size: 16),
        const Gap(8),
        Expanded(
          child: Text(
            "${1.toStringAsFixed(1)} MB storage used",
            style: Theme.of(context).typography.base.copyWith(fontSize: 13),
          ),
        ),
        //     Button.ghost(
        //       // size: ButtonSize.xSmall,
        //       onPressed: _storageSizeMb == 0.0
        //           ? null
        //           : () {
        //               setState(() => _storageSizeMb = 0.0);
        //               showToast(
        //                 context: context,
        //                 builder: (context, overlay) => SurfaceCard(
        //                   child: Basic(
        //                     title: const Text(
        //                       'Site storage & cache cleared',
        //                     ),
        //                     trailing: PrimaryButton(
        //                       size: ButtonSize.small,
        //                       onPressed: () => overlay.close(),
        //                       child: const Text('OK'),
        //                     ),
        //                   ),
        //                 ),
        //               );
        //             },
        //       child: const Text("Clear"),
        //     ),
        //   ],
        // ),
        // const Gap(8),

        // Network Requests
        // Row(
        //   children: [
        //     const Icon(LucideIcons.activity, size: 16),
        //     const Gap(8),
        //     Expanded(
        //       child: Text(
        //         "$_networkRequestsCount network requests",
        //         style: Theme.of(
        //           context,
        //         ).typography.base.copyWith(fontSize: 13),
        //       ),
        //     ),
        //     Button.ghost(
        //       // size: ButtonSize.xSmall,
        //       onPressed: () {
        //         showToast(
        //           context: context,
        //           builder: (context, overlay) => SurfaceCard(
        //             child: Basic(
        //               title: Text(
        //                 'Network Log: $_networkRequestsCount secure requests',
        //               ),
        //               trailing: PrimaryButton(
        //                 size: ButtonSize.small,
        //                 onPressed: () => overlay.close(),
        //                 child: const Text('Close'),
        //               ),
        //             ),
        //           ),
        //         );
        //       },
        //       child: const Text("Details"),
        //     ),
      ],
    );
  }

  Widget _buildPermissionRow(
    String name,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const Gap(8),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).typography.base.copyWith(fontSize: 13),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
