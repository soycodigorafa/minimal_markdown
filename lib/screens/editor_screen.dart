import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_editor/viewmodels/document_viewmodel.dart';
import 'package:markdown_editor/services/file_service.dart';
import 'package:markdown_editor/services/theme_service.dart';
import 'package:window_manager/window_manager.dart';

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

      // Configurar el focus node para manejar eventos de teclado
      _editorFocusNode.onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          // Obtener la posición actual del cursor
          final cursorPosition = _textController.selection.baseOffset;
          if (cursorPosition >= 0) {
            // Obtener el texto actual
            final text = _textController.text;
            // Encontrar el final de la línea actual
            int lineEnd = text.indexOf('\n', cursorPosition);
            if (lineEnd == -1) lineEnd = text.length;

            // Insertar '\' al final de la línea actual y luego un salto de línea
            final beforeCursor = text.substring(0, lineEnd);
            final afterCursor = text.substring(lineEnd);

            // Actualizar el texto con el '\' al final de la línea
            final newText = '$beforeCursor \\\n$afterCursor';
            _textController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                offset: lineEnd + 3,
              ), // +3 por ' \' + '\n'
            );

            return KeyEventResult.handled;
          }
        }
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
      ref.read(documentProvider.notifier)
        ..setFilePath(savedPath)
        ..markAsSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Archivo guardado correctamente')),
      );
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
    final isPreviewMode = ref.watch(previewModeProvider);
    final fontSize = ref.watch(editorFontSizeProvider);

    // Definir los atajos de teclado
    final shortcuts = <ShortcutActivator, Intent>{
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.keyS,
      ): VoidCallbackIntent(() {}),
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.keyO,
      ): VoidCallbackIntent(() {}),
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.keyN,
      ): VoidCallbackIntent(() {}),
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.keyP,
      ): VoidCallbackIntent(() {}),
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
                ref.read(previewModeProvider.notifier).toggle();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                document.fileName + (document.isModified ? " *" : ""),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_open),
                  tooltip: 'Abrir (Ctrl+O)',
                  onPressed: _openFile,
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Guardar (Ctrl+S)',
                  onPressed: _saveFile,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Nuevo documento (Ctrl+N)',
                  onPressed: _newDocument,
                ),
                IconButton(
                  icon: Icon(isPreviewMode ? Icons.edit : Icons.preview),
                  tooltip: 'Cambiar modo (Ctrl+P)',
                  onPressed:
                      () => ref.read(previewModeProvider.notifier).toggle(),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Configuración',
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
            body:
                isPreviewMode
                    ? _buildPreviewMode(document.content, fontSize)
                    : _buildEditorMode(fontSize),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorMode(double fontSize) {
    return Container(
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
    );
  }

  Widget _buildPreviewMode(String content, double fontSize) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Markdown(
        data: content,
        selectable: true,
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
}
