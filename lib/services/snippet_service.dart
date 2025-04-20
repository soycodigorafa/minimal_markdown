import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/markdown_snippets.dart';

/// Service for managing markdown snippets
class SnippetService {
  /// Refocus the editor after inserting a snippet
  void refocusEditor(FocusNode focusNode) {
    // Ensure focus returns to editor
    Future.microtask(() {
      focusNode.requestFocus();
    });
  }

  /// Insert a header at the current cursor position
  void insertHeader(TextEditingController controller, int level) {
    final selectedText = controller.selection.textInside(controller.text);
    final headerText = selectedText.isNotEmpty ? selectedText : 'Heading';
    final snippet = MarkdownSnippets.header(level, text: headerText);

    // Calculate positions to select the heading text for easy editing
    final int startPos = controller.selection.start;
    final int headingPos = snippet.indexOf(headerText);

    // Replace the current selection with the header
    final newText = controller.text.replaceRange(
      controller.selection.start,
      controller.selection.end,
      snippet,
    );

    // Position the cursor to select the heading text
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: startPos + headingPos,
        extentOffset: startPos + headingPos + headerText.length,
      ),
    );
  }

  /// Insert bold formatting
  void insertBold(TextEditingController controller) {
    MarkdownSnippets.wrapSelection(controller, '**', '**');
  }

  /// Insert italic formatting
  void insertItalic(TextEditingController controller) {
    MarkdownSnippets.wrapSelection(controller, '*', '*');
  }

  /// Insert code block
  void insertCodeBlock(TextEditingController controller) {
    final selectedText = controller.selection.textInside(controller.text);
    final codeContent = selectedText.isNotEmpty ? selectedText : 'code here';
    final snippet = MarkdownSnippets.codeBlock(codeContent);

    // Calculate positions for cursor placement
    final int startPos = controller.selection.start;
    final int codePos = snippet.indexOf(codeContent);

    // Replace the current selection with the code block
    final newText = controller.text.replaceRange(
      controller.selection.start,
      controller.selection.end,
      snippet,
    );

    // Position the cursor to select the code content if it was the default placeholder
    if (selectedText.isEmpty) {
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: startPos + codePos,
          extentOffset: startPos + codePos + codeContent.length,
        ),
      );
    } else {
      // If user had selected text, place cursor at the end of the code block
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset:
              startPos +
              codePos +
              codeContent.length +
              4, // +4 for the closing ```
        ),
      );
    }
  }

  /// Insert inline code
  void insertInlineCode(TextEditingController controller) {
    MarkdownSnippets.wrapSelection(controller, '`', '`');
  }

  /// Insert blockquote
  void insertBlockquote(TextEditingController controller) {
    final selectedText = controller.selection.textInside(controller.text);
    final quoteText =
        selectedText.isNotEmpty ? selectedText : 'Blockquote text here';
    final snippet =
        selectedText.isNotEmpty
            ? MarkdownSnippets.blockquote(selectedText)
            : '> $quoteText';

    // Calculate positions for cursor placement
    final int startPos = controller.selection.start;
    final int textPos = snippet.indexOf(quoteText);

    // Replace the current selection with the blockquote
    final newText = controller.text.replaceRange(
      controller.selection.start,
      controller.selection.end,
      snippet,
    );

    // Position the cursor to select the quote text if it was the default placeholder
    if (selectedText.isEmpty) {
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: startPos + textPos,
          extentOffset: startPos + textPos + quoteText.length,
        ),
      );
    } else {
      // If user had selected text, place cursor at the end of the blockquote
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: startPos + snippet.length),
      );
    }
  }

  /// Insert horizontal rule
  void insertHorizontalRule(TextEditingController controller) {
    MarkdownSnippets.insertSnippet(controller, '\n---\n');
  }

  /// Insert link
  void insertLink(TextEditingController controller) {
    final selectedText = controller.selection.textInside(controller.text);
    final linkText = selectedText.isNotEmpty ? selectedText : 'link text';
    final linkUrl = 'https://example.com';
    final snippet = MarkdownSnippets.link(linkText, linkUrl);

    // Calculate positions for cursor placement
    final int startPos = controller.selection.start;
    final int urlPos = snippet.indexOf(linkUrl);

    // Replace the current selection with the link
    final newText = controller.text.replaceRange(
      controller.selection.start,
      controller.selection.end,
      snippet,
    );

    // Position the cursor to select the URL for easy editing
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: startPos + urlPos,
        extentOffset: startPos + urlPos + linkUrl.length,
      ),
    );
  }

  /// Insert image
  void insertImage(TextEditingController controller) {
    final altText = 'alt text';
    final imageUrl = 'https://example.com/image.jpg';
    final snippet = MarkdownSnippets.image(altText, imageUrl);

    // Calculate positions for cursor placement
    final int startPos = controller.selection.start;
    final int urlPos = snippet.indexOf(imageUrl);

    // Replace the current selection with the image
    final newText = controller.text.replaceRange(
      controller.selection.start,
      controller.selection.end,
      snippet,
    );

    // Position the cursor to select the URL for easy editing
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: startPos + urlPos,
        extentOffset: startPos + urlPos + imageUrl.length,
      ),
    );
  }

  /// Insert bullet list
  void insertBulletList(TextEditingController controller) {
    final selectedText = controller.selection.textInside(controller.text);
    if (selectedText.isNotEmpty) {
      final items = selectedText.split('\n');
      final snippet = MarkdownSnippets.bulletList(items);
      controller.value = TextEditingValue(
        text: controller.text.replaceRange(
          controller.selection.start,
          controller.selection.end,
          snippet,
        ),
        selection: TextSelection.collapsed(
          offset: controller.selection.start + snippet.length,
        ),
      );
    } else {
      MarkdownSnippets.insertSnippet(
        controller,
        MarkdownSnippets.bulletList(['Item 1', 'Item 2', 'Item 3']),
      );
    }
  }

  /// Insert numbered list
  void insertNumberedList(TextEditingController controller) {
    final selectedText = controller.selection.textInside(controller.text);
    if (selectedText.isNotEmpty) {
      final items = selectedText.split('\n');
      final snippet = MarkdownSnippets.numberedList(items);
      controller.value = TextEditingValue(
        text: controller.text.replaceRange(
          controller.selection.start,
          controller.selection.end,
          snippet,
        ),
        selection: TextSelection.collapsed(
          offset: controller.selection.start + snippet.length,
        ),
      );
    } else {
      MarkdownSnippets.insertSnippet(
        controller,
        MarkdownSnippets.numberedList(['Item 1', 'Item 2', 'Item 3']),
      );
    }
  }

  /// Insert task list
  void insertTaskList(TextEditingController controller) {
    MarkdownSnippets.insertSnippet(
      controller,
      MarkdownSnippets.taskList([
        MapEntry('Task 1', false),
        MapEntry('Task 2', true),
        MapEntry('Task 3', false),
      ]),
    );
  }

  /// Insert table
  void insertTable(TextEditingController controller) {
    MarkdownSnippets.insertSnippet(
      controller,
      MarkdownSnippets.table(
        ['Header 1', 'Header 2', 'Header 3'],
        [
          ['Row 1, Col 1', 'Row 1, Col 2', 'Row 1, Col 3'],
          ['Row 2, Col 1', 'Row 2, Col 2', 'Row 2, Col 3'],
        ],
      ),
    );
  }
}

/// Provider for the snippet service
final snippetServiceProvider = Provider<SnippetService>((ref) {
  return SnippetService();
});
