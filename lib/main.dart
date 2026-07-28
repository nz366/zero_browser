import 'package:provider/provider.dart';
import 'package:zero_browser/client/collection.dart';
import 'package:zero_browser/providers/history_provider.dart';
import 'package:zero_browser/ui/tab.dart';
import 'package:zero_browser/providers/theme_provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/database/database.dart';
import 'package:zero_browser/providers/bookmark_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  registerDefaults();

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
      debugShowCheckedModeBanner: false,
      home: Scaffold(child: TabPaneWidget()),
    );
  }
}
