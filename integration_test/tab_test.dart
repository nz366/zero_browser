import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/client/collection.dart';
import 'package:zero_browser/database/database.dart';
import 'package:zero_browser/providers/bookmark_provider.dart';
import 'package:zero_browser/providers/history_provider.dart';
import 'package:zero_browser/providers/theme_provider.dart';
import 'package:zero_browser/ui/tab.dart';

Future<void> pumpApp(WidgetTester tester) async {
  registerDefaults();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: appDatabase),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TabProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = context.watch<ThemeProvider>();

          return ShadcnApp(
            themeMode: themeProvider.themeMode,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            home: Scaffold(child: TabPaneWidget()),
          );
        },
      ),
    ),
  );

  await tester.pumpAndSettle(const Duration(seconds: 2));
}

TabProvider getTabProvider(WidgetTester tester) {
  return tester.element(find.byType(TabPaneWidget)).read<TabProvider>();
}

BookmarkProvider getBookmarkProvider(WidgetTester tester) {
  return tester.element(find.byType(TabPaneWidget)).read<BookmarkProvider>();
}

Future<void> addTab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add).first);
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
}

Future<void> closeFocusedTab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.close).first);
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tab management', () {
    testWidgets('starts with one tab', (tester) async {
      await pumpApp(tester);

      expect(getTabProvider(tester).tabs, hasLength(1));
    });

    testWidgets('adding one tab results in two tabs', (tester) async {
      await pumpApp(tester);

      await addTab(tester);

      expect(getTabProvider(tester).tabs, hasLength(2));
    });

    testWidgets('adding three tabs results in four tabs', (tester) async {
      await pumpApp(tester);

      for (var i = 0; i < 3; i++) {
        await addTab(tester);
      }

      expect(getTabProvider(tester).tabs, hasLength(4));
    });

    testWidgets('closing the focused tab removes it', (tester) async {
      await pumpApp(tester);

      await addTab(tester);

      expect(getTabProvider(tester).tabs, hasLength(2));

      await closeFocusedTab(tester);

      expect(getTabProvider(tester).tabs, hasLength(1));
    });

    testWidgets('closing the last tab opens a new tab', (tester) async {
      await pumpApp(tester);

      final provider = getTabProvider(tester);
      provider.closeTab(provider.focusedTab);

      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(getTabProvider(tester).tabs, hasLength(1));
    });

    testWidgets('adding two tabs and closing one leaves two tabs', (
      tester,
    ) async {
      await pumpApp(tester);

      await addTab(tester);
      await addTab(tester);

      expect(getTabProvider(tester).tabs, hasLength(3));

      await closeFocusedTab(tester);

      expect(getTabProvider(tester).tabs, hasLength(2));
    });

    testWidgets('focused index remains valid after closing a tab', (
      tester,
    ) async {
      await pumpApp(tester);

      await addTab(tester);
      await addTab(tester);

      final provider = getTabProvider(tester);
      expect(provider.focused, equals(2));

      await closeFocusedTab(tester);

      expect(provider.focused, lessThan(provider.tabs.length));
    });
  });

  group('Bookmarks', () {
    testWidgets('can add and remove a bookmark', (tester) async {
      await pumpApp(tester);

      final tabs = getTabProvider(tester);
      final bookmarks = getBookmarkProvider(tester);

      tabs.setFocused(0);
      await tester.pumpAndSettle();

      final url = tabs.focusedTab.page.url;

      expect(
        bookmarks.isBookmarked(url),
        isFalse,
        reason: 'The page should not be bookmarked initially.',
      );

      await tester.tap(find.byIcon(Icons.bookmark_outline).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(
        bookmarks.isBookmarked(url),
        isTrue,
        reason: 'Tapping the outline bookmark icon should add the bookmark.',
      );

      await tester.tap(find.byIcon(Icons.bookmark).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(
        bookmarks.isBookmarked(url),
        isFalse,
        reason: 'Tapping the filled bookmark icon should remove the bookmark.',
      );
    });
  });
}
