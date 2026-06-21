import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/providers/history_provider.dart';

class SiteSettingsPopover extends StatefulWidget {
  const SiteSettingsPopover({super.key});

  @override
  State<SiteSettingsPopover> createState() => _SiteSettingsPopoverState();
}

class _SiteSettingsPopoverState extends State<SiteSettingsPopover> {
  bool _locationAllowed = false;
  bool _cameraAllowed = false;
  bool _microphoneAllowed = false;
  bool _notificationsAllowed = true;
  bool _javascriptAllowed = true;

  int _cookiesCount = 4;
  double _storageSizeMb = 1.4;
  int _networkRequestsCount = 18;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TabProvider>(context, listen: false);
    final focusedTab = provider.focusedTab;
    final page = focusedTab.page;
    final uri = Uri.tryParse(page.url);
    final domain = uri != null && uri.host.isNotEmpty ? uri.host : page.url;
    final isSecure = uri != null && uri.scheme == 'https';
    final isLocal = uri != null && uri.scheme == 'file';

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
                  Icon(
                    isSecure
                        ? LucideIcons.lock
                        : isLocal
                        ? LucideIcons.fileCode
                        : LucideIcons.lockOpen,
                    color: isSecure
                        ? Colors.green
                        : isLocal
                        ? Colors.blue
                        : Colors.orange,
                    size: 18,
                  ),
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
                          isSecure
                              ? "Connection is secure"
                              : isLocal
                              ? "Local system file"
                              : "Connection is not secure",
                          // style: Theme.of(context).typography.muted.copyWith(fontSize: 12),
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

              // Permissions section
              Text(
                "Permissions",
                style: Theme.of(
                  context,
                ).typography.semiBold.copyWith(fontSize: 13),
              ),
              const Gap(10),
              _buildPermissionRow(
                "Location",
                LucideIcons.mapPin,
                _locationAllowed,
                (v) {
                  setState(() => _locationAllowed = v);
                },
              ),
              _buildPermissionRow(
                "Camera",
                LucideIcons.camera,
                _cameraAllowed,
                (v) {
                  setState(() => _cameraAllowed = v);
                },
              ),
              _buildPermissionRow(
                "Microphone",
                LucideIcons.mic,
                _microphoneAllowed,
                (v) {
                  setState(() => _microphoneAllowed = v);
                },
              ),
              _buildPermissionRow(
                "Notifications",
                LucideIcons.bell,
                _notificationsAllowed,
                (v) {
                  setState(() => _notificationsAllowed = v);
                },
              ),
              _buildPermissionRow(
                "JavaScript",
                LucideIcons.braces,
                _javascriptAllowed,
                (v) {
                  setState(() => _javascriptAllowed = v);
                },
              ),

              const Divider(height: 24),

              // Cookies & Data
              Row(
                children: [
                  const Icon(LucideIcons.cookie, size: 16),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      "$_cookiesCount cookies in use",
                      style: Theme.of(
                        context,
                      ).typography.base.copyWith(fontSize: 13),
                    ),
                  ),
                  Button.ghost(
                    // size: ButtonSize.xSmall,
                    onPressed: _cookiesCount == 0
                        ? null
                        : () {
                            setState(() => _cookiesCount = 0);
                            showToast(
                              context: context,
                              builder: (context, overlay) => SurfaceCard(
                                child: Basic(
                                  title: const Text(
                                    'Cookies cleared for this site',
                                  ),
                                  trailing: PrimaryButton(
                                    size: ButtonSize.small,
                                    onPressed: () => overlay.close(),
                                    child: const Text('OK'),
                                  ),
                                ),
                              ),
                            );
                          },
                    child: const Text("Clear"),
                  ),
                ],
              ),
              const Gap(8),

              // Cache & Storage
              Row(
                children: [
                  const Icon(LucideIcons.hardDrive, size: 16),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      "${_storageSizeMb.toStringAsFixed(1)} MB storage used",
                      style: Theme.of(
                        context,
                      ).typography.base.copyWith(fontSize: 13),
                    ),
                  ),
                  Button.ghost(
                    // size: ButtonSize.xSmall,
                    onPressed: _storageSizeMb == 0.0
                        ? null
                        : () {
                            setState(() => _storageSizeMb = 0.0);
                            showToast(
                              context: context,
                              builder: (context, overlay) => SurfaceCard(
                                child: Basic(
                                  title: const Text(
                                    'Site storage & cache cleared',
                                  ),
                                  trailing: PrimaryButton(
                                    size: ButtonSize.small,
                                    onPressed: () => overlay.close(),
                                    child: const Text('OK'),
                                  ),
                                ),
                              ),
                            );
                          },
                    child: const Text("Clear"),
                  ),
                ],
              ),
              const Gap(8),

              // Network Requests
              Row(
                children: [
                  const Icon(LucideIcons.activity, size: 16),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      "$_networkRequestsCount network requests",
                      style: Theme.of(
                        context,
                      ).typography.base.copyWith(fontSize: 13),
                    ),
                  ),
                  Button.ghost(
                    // size: ButtonSize.xSmall,
                    onPressed: () {
                      showToast(
                        context: context,
                        builder: (context, overlay) => SurfaceCard(
                          child: Basic(
                            title: Text(
                              'Network Log: $_networkRequestsCount secure requests',
                            ),
                            trailing: PrimaryButton(
                              size: ButtonSize.small,
                              onPressed: () => overlay.close(),
                              child: const Text('Close'),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text("Details"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
