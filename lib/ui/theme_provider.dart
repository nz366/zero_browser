import 'package:flutter/foundation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }

  ThemeData get theme => ThemeData(
    colorScheme: _isDark ? ColorSchemes.darkSlate : ColorSchemes.lightSlate,
  );
}
