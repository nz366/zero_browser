import 'package:provider/provider.dart';
import 'package:zero_browser/client/collection.dart';
import 'package:zero_browser/providers/history_provider.dart';
import 'package:zero_browser/ui/tab.dart';
import 'package:zero_browser/providers/theme_provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/database/database.dart';
import 'package:zero_browser/providers/bookmark_provider.dart';
import 'package:zero_browser/widgets/browser/errors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  registerDefaults();
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return BrowserError(
      heading: "This widget caused an error",
      error: details.exception.toString(),
    );
  };

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: appDatabase),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TabProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ],
      child: const BroswserApp(),
    ),
  );
}

class BroswserApp extends StatelessWidget {
  const BroswserApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return ShadcnApp(
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      home: Scaffold(child: TabPaneWidget()),
    );
  }
}
