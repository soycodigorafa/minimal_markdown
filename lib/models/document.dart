import 'dart:io';

/// Modelo de datos puro para un documento markdown
/// Siguiendo el patrón MVVM, este es el Model
class Document {
  final String content;
  final String filePath;
  final String fileName;
  final bool isModified;

  Document({
    this.content = '',
    this.filePath = '',
    this.fileName = 'Untitled.md',
    this.isModified = false,
  });

  bool get hasFilePath => filePath.isNotEmpty;

  /// Crea una copia del documento con valores actualizados
  Document copyWith({
    String? content,
    String? filePath,
    String? fileName,
    bool? isModified,
  }) {
    return Document(
      content: content ?? this.content,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      isModified: isModified ?? this.isModified,
    );
  }

  /// Derivar un nombre de archivo del path
  static String extractFileName(String path) {
    return path.isEmpty ? 'Untitled.md' : path.split(Platform.pathSeparator).last;
  }
}
