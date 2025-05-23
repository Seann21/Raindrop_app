import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class ThemeNotifier extends StateNotifier<bool> {
  final SharedPreferences prefs;
  static const String key = 'isDarkMode';

  ThemeNotifier(this.prefs) : super(prefs.getBool(key) ?? false);

  void toggle() {
    state = !state;
    prefs.setBool(key, state);
  }
}
