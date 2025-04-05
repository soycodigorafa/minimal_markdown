import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document.dart';

/// ViewModel para manejar la lógica relacionada con documentos
/// Siguiendo el patrón MVVM, este es el ViewModel
class DocumentNotifier extends StateNotifier<Document> {
  DocumentNotifier() : super(Document());

  // Métodos para actualizar el estado
  void updateContent(String newContent) {
    if (state.content != newContent) {
      state = state.copyWith(
        content: newContent,
        isModified: true,
      );
    }
  }

  void setFilePath(String path) {
    state = state.copyWith(
      filePath: path,
      fileName: Document.extractFileName(path),
    );
  }

  void markAsSaved() {
    state = state.copyWith(isModified: false);
  }

  void newDocument() {
    state = Document();
  }
}

/// Provider para el documento
final documentProvider = StateNotifierProvider<DocumentNotifier, Document>(
  (ref) => DocumentNotifier(),
);

/// Provider para manejar el modo de previsualización
class PreviewModeNotifier extends StateNotifier<bool> {
  PreviewModeNotifier() : super(false); // Modo editor por defecto

  void toggle() {
    state = !state;
  }
}

/// Provider para el modo de previsualización
final previewModeProvider = StateNotifierProvider<PreviewModeNotifier, bool>(
  (ref) => PreviewModeNotifier(),
);
