import 'dart:async';

import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/client/event_recorder_client.dart';
import 'package:zero_browser/providers/history_provider.dart';
import 'package:zero_browser/widgets/browser/errors.dart';
import 'package:zero_browser/widgets/browser/network_chart.dart';
import 'package:zero_browser/widgets/browser/data_tree.dart';

class DevToolPanel extends StatefulWidget {
  const DevToolPanel({super.key});

  @override
  State<DevToolPanel> createState() => _DevToolPanelState();
}

class _DevToolPanelState extends State<DevToolPanel> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TabList(
              index: index,
              onChanged: (value) {
                if (value == 1) {
                  context.read<TabProvider>().enableClientEvent();
                }

                setState(() {
                  index = value;
                });
              },
              children: const [
                TabItem(child: Text('Data')),
                TabItem(child: Text('Network')),
              ],
            ),
            Spacer(),
            Button.text(
              child: Icon(Icons.close),
              onPressed: () {
                context.read<TabProvider>().toggleTabSidebar();
              },
            ),
          ],
        ),
        Divider(),
        Expanded(
          child: IndexedStack(
            index: index,
            sizing: StackFit.expand,
            children: [
              DataTab(
                jsonObj: context
                    .watch<TabProvider>()
                    .focusedTab
                    .page
                    .content
                    .map((e) => e.toJson())
                    .toList(),
              ),
              NetworkTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class NetworkTab extends StatefulWidget {
  const NetworkTab({super.key});

  @override
  State<NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<NetworkTab> {
  Timer? timer;
  @override
  void initState() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uclient = context.watch<TabProvider>().focusedTab.client;

    if (uclient is! EventRecordingClient) {
      return BrowserError(
        error: "",
        heading: "No Network Activity",
        retryButton: Button.text(
          child: Text("Start Recording"),
          onPressed: () {
            context.read<TabProvider>().enableClientEvent();
          },
        ),
      );
    }

    return NetworkChart(store: uclient.events);
  }
}
