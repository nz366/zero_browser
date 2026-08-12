import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/client/event_recorder_client.dart';

class NetworkChart extends StatelessWidget {
  final EventStore store;

  const NetworkChart({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),

      child: SingleChildScrollView(
        child: Table(
          rows: [
            TableHeader(
              cells: [
                TableCell(child: Text("URL")),
                TableCell(child: Text("Status")),
                TableCell(child: Text("Size")),
                TableCell(child: Text("Time")),
              ],
            ),
            ...store.events.values.map(
              (event) => TableRow(
                cells: [
                  buildTextCell(event.url),
                  buildTextCell(event.statusCode?.toString() ?? ""),
                  buildTextCell(event.size?.toString() ?? ""),
                  buildTextCell("${event.totalDuration.inMilliseconds}ms"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableCell buildTextCell(String text) {
    return TableCell(
      child: Tooltip(
        tooltip: (_) => Text(text),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
