import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_editor/viewmodels/document_viewmodel.dart';
import 'package:markdown_editor/services/file_service.dart';
import 'package:markdown_editor/services/theme_service.dart';
import 'package:markdown_editor/services/recent_files_service.dart';
import 'package:markdown_editor/widgets/snippet_palette.dart';
import 'package:window_manager/window_manager.dart';

// Enumeración para los modos de visualización
enum ViewMode { editor, preview, split }

// Proveedor para el modo de visualización
final viewModeProvider = StateNotifierProvider<ViewModeNotifier, ViewMode>(
  (ref) => ViewModeNotifier(),
);

class ViewModeNotifier extends StateNotifier<ViewMode> {
  ViewModeNotifier() : super(ViewMode.editor);

  void setMode(ViewMode mode) => state = mode;

  void togglePreview() {
    if (state == ViewMode.editor) {
      state = ViewMode.preview;
    } else {
      state = ViewMode.editor;
    }
  }

  void toggleSplit() {
    if (state == ViewMode.split) {
      state = ViewMode.editor;
    } else {
      state = ViewMode.split;
    }
  }
}

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with WindowListener {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    // Configurar el controlador de texto inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final document = ref.read(documentProvider);
      _textController.text = document.content;

      // Capturar cambios en el texto
      _textController.addListener(() {
        if (_textController.text != ref.read(documentProvider).content) {
          ref
              .read(documentProvider.notifier)
              .updateContent(_textController.text);
        }
      });

      // Ya no necesitamos manejar el evento de Enter para insertar backslashes
      // porque Markdown ahora renderiza correctamente con solo saltos de línea
      _editorFocusNode.onKeyEvent = (node, event) {
        // Mantener el focus node para otros eventos de teclado que podríamos querer manejar en el futuro
        return KeyEventResult.ignored;
      };
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _textController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final document = ref.read(documentProvider);
    if (document.isModified) {
      final shouldClose = await _showUnsavedChangesDialog();
      if (!shouldClose) {
        await windowManager.focus();
        return;
      }
    }
    await windowManager.destroy();
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Cambios sin guardar'),
              content: const Text(
                'Tienes cambios sin guardar. ¿Quieres salir sin guardarlos?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Salir sin guardar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Métodos para manejar archivos
  Future<void> _openFile() async {
    final fileService = ref.read(fileServiceProvider);
    final content = await fileService.openFile();

    if (content != null && content.isNotEmpty) {
      // Obtener la ruta del archivo seleccionado
      final path = await fileService.getLastOpenedPath();
      if (path != null) {
        // Add to recent files
        ref.read(recentFilesProvider.notifier).addRecentFile(path);
        
        ref.read(documentProvider.notifier)
          ..setFilePath(path)
          ..updateContent(content)
          ..markAsSaved();
        _textController.text = content;
      }
    }
  }

  Future<void> _saveFile() async {
    final document = ref.read(documentProvider);
    final fileService = ref.read(fileServiceProvider);

    final savedPath = await fileService.saveFile(
      document.content,
      path: document.hasFilePath ? document.filePath : null,
    );

    if (savedPath != null) {
      // Add to recent files
      ref.read(recentFilesProvider.notifier).addRecentFile(savedPath);
      
      ref.read(documentProvider.notifier)
        ..setFilePath(savedPath)
        ..markAsSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo guardado correctamente')),
        );
      }
    }
  }

  void _newDocument() {
    final document = ref.read(documentProvider);
    if (document.isModified) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Cambios sin guardar'),
              content: const Text(
                '¿Quieres crear un nuevo documento sin guardar los cambios actuales?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(documentProvider.notifier).newDocument();
                    _textController.text = '';
                    Navigator.of(context).pop();
                  },
                  child: const Text('Nuevo documento'),
                ),
              ],
            ),
      );
    } else {
      ref.read(documentProvider.notifier).newDocument();
      _textController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = ref.watch(documentProvider);
    final viewMode = ref.watch(viewModeProvider);
    final fontSize = ref.watch(editorFontSizeProvider);

    // Definir los atajos de teclado basados en la plataforma
    final modifierKey =
        Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;
    final shortcuts = <ShortcutActivator, Intent>{
      LogicalKeySet(modifierKey, LogicalKeyboardKey.keyS): VoidCallbackIntent(
        () {},
      ),
      LogicalKeySet(modifierKey, LogicalKeyboardKey.keyO): VoidCallbackIntent(
        () {},
      ),
      LogicalKeySet(modifierKey, LogicalKeyboardKey.keyN): VoidCallbackIntent(
        () {},
      ),
      LogicalKeySet(modifierKey, LogicalKeyboardKey.keyP): VoidCallbackIntent(
        () {},
      ),
      LogicalKeySet(modifierKey, LogicalKeyboardKey.keyD): VoidCallbackIntent(
        () {},
      ),
    };

    // Acciones para los atajos
    final actions = <Type, Action<Intent>>{
      VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
        onInvoke: (VoidCallbackIntent intent) {
          // Las acciones reales se definen en los Listeners
          return null;
        },
      ),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actions,
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            final isCtrlPressed =
                Platform.isMacOS
                    ? HardwareKeyboard.instance.isMetaPressed
                    : HardwareKeyboard.instance.isControlPressed;
            if (event is KeyDownEvent) {
              // Guardar (Ctrl+S)
              if (event.logicalKey == LogicalKeyboardKey.keyS &&
                  isCtrlPressed) {
                _saveFile();
                return KeyEventResult.handled;
              }
              // Abrir (Ctrl+O)
              else if (event.logicalKey == LogicalKeyboardKey.keyO &&
                  isCtrlPressed) {
                _openFile();
                return KeyEventResult.handled;
              }
              // Nuevo documento (Ctrl+N)
              else if (event.logicalKey == LogicalKeyboardKey.keyN &&
                  isCtrlPressed) {
                _newDocument();
                return KeyEventResult.handled;
              }
              // Alternar vista previa (Ctrl+P)
              else if (event.logicalKey == LogicalKeyboardKey.keyP &&
                  isCtrlPressed) {
                ref.read(viewModeProvider.notifier).togglePreview();
                return KeyEventResult.handled;
              }
              // Alternar vista dividida (Ctrl+D)
              else if (event.logicalKey == LogicalKeyboardKey.keyD &&
                  isCtrlPressed) {
                ref.read(viewModeProvider.notifier).toggleSplit();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Scaffold(
            appBar: AppBar(
              surfaceTintColor: Colors.white,
              shadowColor: Theme.of(context).colorScheme.surface,
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                document.fileName + (document.isModified ? " *" : ""),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.home),
                  tooltip: 'Inicio',
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                ),
                IconButton(
                  icon: const Icon(Icons.file_open),
                  tooltip: 'Abrir (${Platform.isMacOS ? "⌘" : "Ctrl"}+O)',
                  onPressed: _openFile,
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Guardar (${Platform.isMacOS ? "⌘" : "Ctrl"}+S)',
                  onPressed: _saveFile,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip:
                      'Nuevo documento (${Platform.isMacOS ? "⌘" : "Ctrl"}+N)',
                  onPressed: _newDocument,
                ),
                IconButton(
                  icon: Icon(
                    viewMode == ViewMode.preview ? Icons.edit : Icons.preview,
                  ),
                  tooltip:
                      'Cambiar modo (${Platform.isMacOS ? "⌘" : "Ctrl"}+P)',
                  onPressed:
                      () => ref.read(viewModeProvider.notifier).togglePreview(),
                ),
                IconButton(
                  icon: Icon(
                    viewMode == ViewMode.split
                        ? Icons.fullscreen
                        : Icons.splitscreen,
                  ),
                  tooltip:
                      'Vista dividida (${Platform.isMacOS ? "⌘" : "Ctrl"}+D)',
                  onPressed:
                      () => ref.read(viewModeProvider.notifier).toggleSplit(),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Configuración',
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
            body: () {
              switch (viewMode) {
                case ViewMode.editor:
                  return _buildEditorMode(fontSize);
                case ViewMode.preview:
                  return _buildPreviewMode(document.content, fontSize);
                case ViewMode.split:
                  return _buildSplitMode(document.content, fontSize);
              }
            }(),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorMode(double fontSize) {
    return Column(
      children: [
        // Snippet palette
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.0,
              ),
            ),
          ),
          child: SnippetPalette(
            textController: _textController,
            focusNode: _editorFocusNode,
          ),
        ),
        // Editor
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _textController,
              focusNode: _editorFocusNode,
              maxLines: null,
              expands: true,
              style: TextStyle(fontSize: fontSize, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Escribe tu markdown aquí...',
              ),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewMode(String content, double fontSize) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Markdown(
        data: content,
        selectable: true,
        softLineBreak: true, // Render single line breaks as <br>
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(fontSize: fontSize),
          h1: TextStyle(fontSize: fontSize * 2.0),
          h2: TextStyle(fontSize: fontSize * 1.75),
          h3: TextStyle(fontSize: fontSize * 1.5),
          h4: TextStyle(fontSize: fontSize * 1.25),
          h5: TextStyle(fontSize: fontSize * 1.1),
          h6: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }

  Widget _buildSplitMode(String content, double fontSize) {
    return Column(
      children: [
        // Snippet palette
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.0,
              ),
            ),
          ),
          child: SnippetPalette(
            textController: _textController,
            focusNode: _editorFocusNode,
          ),
        ),
        // Split view with editor and preview
        Expanded(
          child: Row(
            children: [
              // Editor side
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _textController,
                    focusNode: _editorFocusNode,
                    maxLines: null,
                    expands: true,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontFamily: 'monospace',
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Escribe tu markdown aquí...',
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ),
              // Vertical divider
              Container(width: 1.0, color: Theme.of(context).dividerColor),
              // Preview side
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Markdown(
                    data: content,
                    selectable: true,
                    softLineBreak: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(fontSize: fontSize),
                      h1: TextStyle(fontSize: fontSize * 2.0),
                      h2: TextStyle(fontSize: fontSize * 1.75),
                      h3: TextStyle(fontSize: fontSize * 1.5),
                      h4: TextStyle(fontSize: fontSize * 1.25),
                      h5: TextStyle(fontSize: fontSize * 1.1),
                      h6: TextStyle(fontSize: fontSize),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
