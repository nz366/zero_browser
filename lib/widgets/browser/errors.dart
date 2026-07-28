import 'package:shadcn_flutter/shadcn_flutter.dart';

class BrowserError extends StatelessWidget {
  final String error;
  final Function()? onRetry;
  const BrowserError(this.onRetry, {super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.gray),
            const SizedBox(height: 12),
            const Text(
              "This page couldn't load",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 6),
            SelectableText(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.gray, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (onRetry != null)
              Button.outline(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
