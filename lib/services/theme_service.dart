import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EditorFontSize { small, medium, large }

class ThemeSettings {
  final ThemeMode themeMode;
  final String fontFamily;
  final EditorFontSize fontSize;
  
  const ThemeSettings({
    this.themeMode = ThemeMode.system,
    this.fontFamily = 'Roboto Mono',
    this.fontSize = EditorFontSize.medium,
  });
  
  ThemeSettings copyWith({
    ThemeMode? themeMode,
    String? fontFamily,
    EditorFontSize? fontSize,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }
  
  // Convertir ThemeMode a string para SharedPreferences
  static String themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
  
  // Convertir string a ThemeMode
  static ThemeMode stringToThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  // Convertir EditorFontSize a string
  static String fontSizeToString(EditorFontSize size) {
    switch (size) {
      case EditorFontSize.small:
        return 'small';
      case EditorFontSize.large:
        return 'large';
      default:
        return 'medium';
    }
  }
  
  // Convertir string a EditorFontSize
  static EditorFontSize stringToFontSize(String? value) {
    switch (value) {
      case 'small':
        return EditorFontSize.small;
      case 'large':
        return EditorFontSize.large;
      default:
        return EditorFontSize.medium;
    }
  }
}

class ThemeNotifier extends StateNotifier<ThemeSettings> {
  late SharedPreferences _prefs;
  
  ThemeNotifier() : super(const ThemeSettings()) {
    _initPrefs();
  }
  
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final settings = _loadSettings();
    state = settings;
  }
  
  ThemeSettings _loadSettings() {
    final themeStr = _prefs.getString('theme_mode') ?? 'system';
    final fontFamily = _prefs.getString('font_family') ?? 'Roboto Mono';
    final fontSizeStr = _prefs.getString('font_size') ?? 'medium';
    
    return ThemeSettings(
      themeMode: ThemeSettings.stringToThemeMode(themeStr),
      fontFamily: fontFamily,
      fontSize: ThemeSettings.stringToFontSize(fontSizeStr),
    );
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString('theme_mode', ThemeSettings.themeModeToString(mode));
    state = state.copyWith(themeMode: mode);
  }
  
  Future<void> setFontFamily(String fontFamily) async {
    await _prefs.setString('font_family', fontFamily);
    state = state.copyWith(fontFamily: fontFamily);
  }
  
  Future<void> setFontSize(EditorFontSize size) async {
    await _prefs.setString('font_size', ThemeSettings.fontSizeToString(size));
    state = state.copyWith(fontSize: size);
  }
  
  // Obtener los temas definidos
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    fontFamily: state.fontFamily,
  );
  
  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    fontFamily: state.fontFamily,
  );
}

// Providers para el tema
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeSettings>((ref) {
  return ThemeNotifier();
});

// Provider para el tamaño de fuente
final editorFontSizeProvider = Provider<double>((ref) {
  final fontSize = ref.watch(themeNotifierProvider).fontSize;
  switch (fontSize) {
    case EditorFontSize.small:
      return 14.0;
    case EditorFontSize.large:
      return 18.0;
    default:
      return 16.0;
  }
});
