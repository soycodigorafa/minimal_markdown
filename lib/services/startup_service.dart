import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StartupMode {
  createNew,
  openRecent,
  showHome,
}

final startupModeProvider =
    StateNotifierProvider<StartupModeNotifier, StartupMode>(
  (ref) => StartupModeNotifier(),
);

class StartupModeNotifier extends StateNotifier<StartupMode> {
  StartupModeNotifier() : super(StartupMode.showHome) {
    _loadStartupMode();
  }

  static const String _prefsKey = 'startup_mode';

  Future<void> _loadStartupMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_prefsKey);
      
      if (modeIndex != null && modeIndex < StartupMode.values.length) {
        state = StartupMode.values[modeIndex];
      }
    } catch (e) {
      // Default to showHome if there's an error
      state = StartupMode.showHome;
    }
  }

  Future<void> setStartupMode(StartupMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, mode.index);
    } catch (e) {
      // Silently fail, the UI will still reflect the change
    }
  }
}
