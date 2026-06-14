import 'package:drift/drift.dart'; // Required for Value()
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/database/database.dart';

enum ThemeSetting {
  system('system'),
  light('light'),
  dark('dark');

  final String value;
  const ThemeSetting(this.value);

  // Helper to reconstruct the enum from database strings
  static ThemeSetting fromString(String? value) {
    return ThemeSetting.values.firstWhere(
      (element) => element.value == value,
      orElse: () => ThemeSetting.system,
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeSetting _currentSetting = ThemeSetting.system;

  ThemeSetting get currentSetting => _currentSetting;

  // Flutter's built-in ThemeMode handles the system brightness switching logic
  ThemeMode get themeMode {
    switch (_currentSetting) {
      case ThemeSetting.light:
        return ThemeMode.light;
      case ThemeSetting.dark:
        return ThemeMode.dark;
      case ThemeSetting.system:
        return ThemeMode.system;
    }
  }

  // Fallback styling for shadcn_flutter schemes
  ThemeData get lightTheme => ThemeData(colorScheme: ColorSchemes.lightSlate);
  ThemeData get darkTheme => ThemeData(colorScheme: ColorSchemes.darkSlate);

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final pref = await (appDatabase.select(
      appDatabase.preferences,
    )..where((t) => t.id.equals("theme_mode"))).getSingleOrNull();

    if (pref != null) {
      _currentSetting = ThemeSetting.fromString(pref.value);
      notifyListeners();
    }
  }

  Future<void> updateTheme(ThemeSetting newSetting) async {
    if (_currentSetting == newSetting) return;

    _currentSetting = newSetting;
    notifyListeners();

    // Upsert into database
    await appDatabase
        .into(appDatabase.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion(
            id: const Value("theme_mode"),
            value: Value(newSetting.value),
          ),
        );
  }

  void toggle() {
    if (currentSetting == ThemeSetting.dark) {
      updateTheme(ThemeSetting.light);
    } else {
      updateTheme(ThemeSetting.dark);
    }
  }
}
