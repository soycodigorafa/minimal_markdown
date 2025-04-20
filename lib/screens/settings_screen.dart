import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_editor/services/theme_service.dart';
import 'package:markdown_editor/services/startup_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sección de tema
          _buildSectionTitle(context, 'Apariencia'),
          _buildThemeSelector(context, ref, themeSettings.themeMode),

          const Divider(),

          // Sección de tipografía
          _buildSectionTitle(context, 'Tipografía'),
          _buildFontFamilySelector(context, ref, themeSettings.fontFamily),
          _buildFontSizeSelector(context, ref, themeSettings.fontSize),

          const Divider(),

          // Sección de inicio
          _buildSectionTitle(context, 'Inicio'),
          _buildStartupOptions(context, ref),

          const Divider(),

          // Sección "Acerca de"
          _buildSectionTitle(context, 'Acerca de'),
          ListTile(
            title: const Text('Markdown Editor'),
            subtitle: const Text(
              'Un editor minimalista de markdown para escritorio',
            ),
            trailing: const Text('v1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentTheme,
  ) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Claro'),
            value: ThemeMode.light,
            groupValue: currentTheme,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeNotifierProvider.notifier).setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Oscuro'),
            value: ThemeMode.dark,
            groupValue: currentTheme,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeNotifierProvider.notifier).setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Sistema'),
            value: ThemeMode.system,
            groupValue: currentTheme,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeNotifierProvider.notifier).setThemeMode(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontFamilySelector(
    BuildContext context,
    WidgetRef ref,
    String currentFont,
  ) {
    final fonts = [
      'Roboto Mono',
      'Consolas',
      'Courier New',
      'Source Code Pro',
      'Fira Code',
    ];

    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Fuente del editor',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final font in fonts)
            RadioListTile<String>(
              title: Text(font, style: TextStyle(fontFamily: font)),
              value: font,
              groupValue: currentFont,
              onChanged: (String? value) {
                if (value != null) {
                  ref.read(themeNotifierProvider.notifier).setFontFamily(value);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSelector(
    BuildContext context,
    WidgetRef ref,
    EditorFontSize currentSize,
  ) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Tamaño de fuente',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioListTile<EditorFontSize>(
            title: const Text('Pequeño (14px)'),
            value: EditorFontSize.small,
            groupValue: currentSize,
            onChanged: (EditorFontSize? value) {
              if (value != null) {
                ref.read(themeNotifierProvider.notifier).setFontSize(value);
              }
            },
          ),
          RadioListTile<EditorFontSize>(
            title: const Text('Mediano (16px)'),
            value: EditorFontSize.medium,
            groupValue: currentSize,
            onChanged: (EditorFontSize? value) {
              if (value != null) {
                ref.read(themeNotifierProvider.notifier).setFontSize(value);
              }
            },
          ),
          RadioListTile<EditorFontSize>(
            title: const Text('Grande (18px)'),
            value: EditorFontSize.large,
            groupValue: currentSize,
            onChanged: (EditorFontSize? value) {
              if (value != null) {
                ref.read(themeNotifierProvider.notifier).setFontSize(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStartupOptions(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(startupModeProvider);

    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Al iniciar la aplicación',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioListTile<StartupMode>(
            title: const Text('Crear un nuevo documento'),
            value: StartupMode.createNew,
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(startupModeProvider.notifier).setStartupMode(value);
              }
            },
          ),
          RadioListTile<StartupMode>(
            title: const Text('Abrir el documento más reciente'),
            value: StartupMode.openRecent,
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(startupModeProvider.notifier).setStartupMode(value);
              }
            },
          ),
          RadioListTile<StartupMode>(
            title: const Text('Mostrar la pantalla de inicio'),
            value: StartupMode.showHome,
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(startupModeProvider.notifier).setStartupMode(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
