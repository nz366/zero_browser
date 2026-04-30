import 'package:provider/provider.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/client/hosts/chrome.dart';
import 'package:zero_browser/client/hosts/github.dart';
import 'package:zero_browser/client/hosts/gram.dart';
import 'package:zero_browser/client/hosts/hackernews.dart';
import 'package:zero_browser/client/hosts/markdown.dart';
import 'package:zero_browser/client/hosts/redlib.dart';
import 'package:zero_browser/client/hosts/wikimedia.dart';
import 'package:zero_browser/providers/history_provider.dart';
import 'package:zero_browser/ui/tab.dart';
import 'package:zero_browser/ui/theme_provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/database/database.dart';
import 'package:zero_browser/providers/bookmark_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  startChromeExtensionRequestHost();
  RequesterRegistry.register(HackernewsRequest());
  RequesterRegistry.register(MarkdownRequest());
  RequesterRegistry.register(RedlibRequest());
  RequesterRegistry.register(Mediawiki());
  RequesterRegistry.register(GiteaRequest());
  RequesterRegistry.register(GramRequest());
  RequesterRegistry.register(GurRequest());
  await Highlighter.initialize(['dart']);

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
    final theme = context.watch<ThemeProvider>().theme;
    return ShadcnApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(child: TabPaneProviderExample()),
    );
  }
}
