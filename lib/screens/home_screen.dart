import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_editor/models/recent_file.dart';
import 'package:markdown_editor/services/file_service.dart';
import 'package:markdown_editor/services/recent_files_service.dart';
import 'package:markdown_editor/viewmodels/document_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentFiles = ref.watch(recentFilesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Editor'),
        surfaceTintColor: Colors.white,
        shadowColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildQuickActions(context, ref),
                const SizedBox(height: 32),
                _buildRecentFiles(context, ref, recentFiles),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionCard(
              context,
              icon: Icons.add,
              title: 'Nuevo documento',
              onTap: () => _createNewDocument(context, ref),
            ),
            const SizedBox(width: 16),
            _buildActionCard(
              context,
              icon: Icons.file_open,
              title: 'Abrir archivo',
              onTap: () => _openFile(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentFiles(
    BuildContext context, 
    WidgetRef ref, 
    List<RecentFile> recentFiles
  ) {
    if (recentFiles.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Archivos recientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No hay archivos recientes',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Archivos recientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Limpiar historial'),
                onPressed: () {
                  ref.read(recentFilesProvider.notifier).clearRecentFiles();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: recentFiles.length,
              itemBuilder: (context, index) {
                final file = recentFiles[index];
                final fileExists = File(file.path).existsSync();
                
                return ListTile(
                  leading: Icon(
                    Icons.description,
                    color: fileExists ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    file.name,
                    style: TextStyle(
                      color: fileExists ? null : Colors.grey,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          file.path,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fileExists ? Colors.grey : Colors.grey.withOpacity(0.5),
                          ),
                        ),
                      ),
                      Text(
                        '${file.lastOpened.day}/${file.lastOpened.month}/${file.lastOpened.year} ${file.lastOpened.hour}:${file.lastOpened.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: fileExists ? Colors.grey : Colors.grey.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  enabled: fileExists,
                  onTap: fileExists
                      ? () => _openRecentFile(context, ref, file.path)
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Eliminar del historial',
                    onPressed: () {
                      ref.read(recentFilesProvider.notifier).removeRecentFile(file.path);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewDocument(BuildContext context, WidgetRef ref) async {
    ref.read(documentProvider.notifier).newDocument();
    Navigator.pushReplacementNamed(context, '/editor');
  }

  Future<void> _openFile(BuildContext context, WidgetRef ref) async {
    final fileService = ref.read(fileServiceProvider);
    final content = await fileService.openFile();

    if (content != null && content.isNotEmpty) {
      final path = await fileService.getLastOpenedPath();
      if (path != null) {
        // Add to recent files
        ref.read(recentFilesProvider.notifier).addRecentFile(path);
        
        // Update document
        ref.read(documentProvider.notifier)
          ..setFilePath(path)
          ..updateContent(content)
          ..markAsSaved();
          
        // Navigate to editor
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/editor');
        }
      }
    }
  }

  Future<void> _openRecentFile(
    BuildContext context, 
    WidgetRef ref, 
    String filePath
  ) async {
    final file = File(filePath);
    if (await file.exists()) {
      final content = await file.readAsString();
      
      // Add to recent files (updates timestamp)
      ref.read(recentFilesProvider.notifier).addRecentFile(filePath);
      
      // Update document
      ref.read(documentProvider.notifier)
        ..setFilePath(filePath)
        ..updateContent(content)
        ..markAsSaved();
        
      // Navigate to editor
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/editor');
      }
    } else {
      // File doesn't exist anymore, show error and remove from recent files
      ref.read(recentFilesProvider.notifier).removeRecentFile(filePath);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El archivo ya no existe'),
          ),
        );
      }
    }
  }
}
