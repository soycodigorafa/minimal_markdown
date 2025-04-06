import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_editor/services/recent_files_service.dart';
import 'package:markdown_editor/services/startup_service.dart';
import 'package:markdown_editor/viewmodels/document_viewmodel.dart';

/// Widget that handles the startup logic based on the user's preference
class StartupHandler extends ConsumerStatefulWidget {
  const StartupHandler({super.key});

  @override
  ConsumerState<StartupHandler> createState() => _StartupHandlerState();
}

class _StartupHandlerState extends ConsumerState<StartupHandler> {
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure the context is ready for navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStartup(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while we decide where to navigate
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Future<void> _handleStartup(BuildContext context) async {
    // Get the startup mode
    final startupMode = ref.read(startupModeProvider);

    switch (startupMode) {
      case StartupMode.createNew:
        // Create a new document and navigate to editor
        ref.read(documentProvider.notifier).newDocument();
        Navigator.pushReplacementNamed(context, '/editor');
        break;

      case StartupMode.openRecent:
        // Try to open the most recent file
        final recentFiles = ref.read(recentFilesProvider);

        if (recentFiles.isNotEmpty) {
          final mostRecentFile = recentFiles.first;
          final file = File(mostRecentFile.path);

          if (await file.exists()) {
            final content = await file.readAsString();

            // Update document
            ref.read(documentProvider.notifier)
              ..setFilePath(mostRecentFile.path)
              ..updateContent(content)
              ..markAsSaved();

            // Navigate to editor
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/editor');
              return;
            }
          }
        }

        // If we couldn't open a recent file, create a new document
        ref.read(documentProvider.notifier).newDocument();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/editor');
        }
        break;

      case StartupMode.showHome:
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
        break;
    }
  }
}
