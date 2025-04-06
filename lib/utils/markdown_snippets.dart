import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Utility class for generating Markdown element snippets
class MarkdownSnippets {
  /// Insert a header with the specified level (1-6)
  static String header(int level, {String text = 'Heading'}) {
    if (level < 1 || level > 6) {
      throw ArgumentError('Header level must be between 1 and 6');
    }
    return '${'#' * level} $text';
  }

  /// Insert a bold text snippet
  static String bold(String text) {
    return '**$text**';
  }

  /// Insert an italic text snippet
  static String italic(String text) {
    return '*$text*';
  }

  /// Insert a code block with optional language
  static String codeBlock(String code, {String language = ''}) {
    return '```$language\n$code\n```';
  }

  /// Insert an inline code snippet
  static String inlineCode(String code) {
    return '`$code`';
  }

  /// Insert a blockquote
  static String blockquote(String text) {
    // Split by newlines and add > to each line
    final lines = text.split('\n');
    return lines.map((line) => '> $line').join('\n');
  }

  /// Insert a horizontal rule
  static String horizontalRule() {
    return '---';
  }

  /// Insert a link
  static String link(String text, String url) {
    return '[$text]($url)';
  }

  /// Insert an image
  static String image(String altText, String url) {
    return '![$altText]($url)';
  }

  /// Insert a bullet list with items
  static String bulletList(List<String> items) {
    return items.map((item) => '- $item').join('\n');
  }

  /// Insert a numbered list with items
  static String numberedList(List<String> items) {
    final result = <String>[];
    for (int i = 0; i < items.length; i++) {
      result.add('${i + 1}. ${items[i]}');
    }
    return result.join('\n');
  }

  /// Insert a task list with items
  static String taskList(List<MapEntry<String, bool>> items) {
    return items
        .map((item) => '- [${item.value ? 'x' : ' '}] ${item.key}')
        .join('\n');
  }

  /// Insert a table with headers and rows
  static String table(List<String> headers, List<List<String>> rows) {
    if (headers.isEmpty) {
      throw ArgumentError('Headers cannot be empty');
    }

    final result = <String>[];
    
    // Add headers
    result.add('| ${headers.join(' | ')} |');
    
    // Add separator
    result.add('| ${headers.map((_) => '---').join(' | ')} |');
    
    // Add rows
    for (final row in rows) {
      if (row.length != headers.length) {
        throw ArgumentError('Row length must match header length');
      }
      result.add('| ${row.join(' | ')} |');
    }
    
    return result.join('\n');
  }

  /// Helper method to insert a snippet at the current cursor position in a TextEditingController
  /// with smart cursor positioning for easy editing
  static void insertSnippet(TextEditingController controller, String snippet) {
    final selection = controller.selection;
    final text = controller.text;
    
    // Find placeholder text to select after insertion
    final placeholderMatch = RegExp(r'(link text|code here|Heading|alt text|Item 1|Task 1|Header 1|Row 1, Col 1)').firstMatch(snippet);
    int selectionStart = selection.baseOffset + snippet.length;
    int selectionEnd = selectionStart;
    
    if (placeholderMatch != null) {
      // Calculate positions to select the placeholder text
      final placeholder = placeholderMatch.group(0)!;
      final placeholderStart = snippet.indexOf(placeholder);
      final placeholderEnd = placeholderStart + placeholder.length;
      
      selectionStart = selection.baseOffset + placeholderStart;
      selectionEnd = selection.baseOffset + placeholderEnd;
    }
    
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      snippet,
    );
    
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selectionStart,
        extentOffset: selectionEnd,
      ),
    );
  }

  /// Helper method to wrap selected text with prefix and suffix
  /// If no text is selected, inserts a placeholder and selects it for easy editing
  static void wrapSelection(
    TextEditingController controller,
    String prefix,
    String suffix,
  ) {
    final selection = controller.selection;
    if (selection.isCollapsed) {
      // No selection, insert the prefix and suffix with placeholder text in between
      final placeholder = _getPlaceholderForWrapper(prefix);
      final newText = controller.text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$placeholder$suffix',
      );
      
      // Position cursor to select the placeholder text for easy replacement
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.baseOffset + prefix.length,
          extentOffset: selection.baseOffset + prefix.length + placeholder.length,
        ),
      );
    } else {
      // Wrap the selected text
      final selectedText = controller.text.substring(
        selection.start,
        selection.end,
      );
      
      final newText = controller.text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      
      // Maintain the selection of the wrapped text
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.baseOffset + prefix.length,
          extentOffset: selection.extentOffset + prefix.length,
        ),
      );
    }
  }
  
  /// Returns an appropriate placeholder based on the wrapper type
  static String _getPlaceholderForWrapper(String prefix) {
    switch (prefix) {
      case '**':
        return 'bold text';
      case '*':
        return 'italic text';
      case '`':
        return 'code';
      default:
        return 'text';
    }
  }
}
