import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Servicio para manejar operaciones de archivos
class FileService {
  String? _lastOpenedPath;
  
  /// Abrir un archivo markdown
  Future<String?> openFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        _lastOpenedPath = filePath;
        final file = File(filePath);
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      // Manejo de errores
      print('Error al abrir el archivo: $e');
      return null;
    }
  }

  /// Guardar el contenido en un archivo
  Future<String?> saveFile(String content, {String? path}) async {
    try {
      String? filePath = path;
      
      if (filePath == null) {
        // Si no hay ruta, pedimos al usuario que elija dónde guardar
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar archivo markdown',
          fileName: 'documento.md',
          type: FileType.custom,
          allowedExtensions: ['md'],
        );
        
        if (outputPath == null) {
          return null; // Usuario canceló
        }
        
        filePath = outputPath;
      }
      
      final file = File(filePath);
      await file.writeAsString(content);
      _lastOpenedPath = filePath;
      
      return filePath;
    } catch (e) {
      print('Error al guardar el archivo: $e');
      return null;
    }
  }
  
  /// Obtiene la ruta del último archivo abierto o guardado
  Future<String?> getLastOpenedPath() async {
    return _lastOpenedPath;
  }
}

/// Provider para el servicio de archivos
final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});
