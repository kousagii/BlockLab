import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceController extends ChangeNotifier {
  final SharedPreferences preferences;
  late ThemeMode _mode;
  AppearanceController(this.preferences) {
    _mode = switch (preferences.getString('appearance.mode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
  ThemeMode get mode => _mode;
  Future<void> setMode(ThemeMode mode) async {
    if (!await preferences.setString('appearance.mode', mode.name)) {
      throw StateError('Could not save your appearance preference.');
    }
    _mode = mode;
    notifyListeners();
  }
}

class AppearanceScope extends InheritedNotifier<AppearanceController> {
  const AppearanceScope({
    super.key,
    required AppearanceController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppearanceController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()!.notifier!;
}
