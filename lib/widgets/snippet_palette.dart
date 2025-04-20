import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/snippet_service.dart';

class SnippetPalette extends ConsumerWidget {
  final TextEditingController textController;
  final FocusNode focusNode;

  const SnippetPalette({
    super.key,
    required this.textController,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snippetService = ref.watch(snippetServiceProvider);

    return Wrap(
      spacing: 4,
      children: [
        // Headers
        _buildPopupMenuButton(
          context,
          tooltip: 'Headings',
          icon: Icons.title,
          itemBuilder:
              (context) => [
                for (int i = 1; i <= 6; i++)
                  PopupMenuItem(
                    value: i,
                    child: Text(
                      'H$i',
                      style: TextStyle(fontWeight: _getHeaderWeight(i)),
                    ),
                  ),
              ],
          onSelected: (int level) {
            snippetService.insertHeader(textController, level);
            snippetService.refocusEditor(focusNode);
          },
        ),

        // Text formatting
        _buildIconButton(
          context,
          tooltip: 'Bold',
          icon: Icons.format_bold,
          onPressed: () {
            snippetService.insertBold(textController);
            snippetService.refocusEditor(focusNode);
          },
        ),
        _buildIconButton(
          context,
          tooltip: 'Italic',
          icon: Icons.format_italic,
          onPressed: () {
            snippetService.insertItalic(textController);
            snippetService.refocusEditor(focusNode);
          },
        ),

        // Code
        _buildIconButton(
          context,
          tooltip: 'Code Block',
          icon: Icons.code,
          onPressed: () {
            snippetService.insertCodeBlock(textController);
            snippetService.refocusEditor(focusNode);
          },
        ),
        _buildIconButton(
          context,
          tooltip: 'Inline Code',
          icon: Icons.code_rounded,
          onPressed: () {
            snippetService.insertInlineCode(textController);
            snippetService.refocusEditor(focusNode);
          },
        ),

        // Lists
        _buildIconButton(
          context,
          tooltip: 'Bullet List',
          icon: Icons.format_list_bulleted,
          onPressed: () {
            snippetService.insertBulletList(textController);
            snippetService.refocusEditor(focusNode);
          },
        ),
        _buildIconButton(
          context,
          tooltip: 'Numbered List',
          icon: Icons.format_list_numbered,
          onPressed: () {
            snippetService.insertNumberedList(textController);
            snippetService.refocusEditor(focusNode);
          },
        ),
        _buildIconButton(
          context,
          tooltip: 'Task List',
          icon: Icons.checklist,
          onPressed: () {
            snippetService.insertTaskList(textController);
            snippetService.refocusEditor(focusNode);
          },
        ),

        // Other elements
        _buildIconButton(
          context,
          tooltip: 'Blockquote',
          icon: Icons.format_quote,
          onPressed: () {
            snippetService.insertBlockquote(textController);
            snippetService.refocusEditor(focusNode);
          },
        ),
        _buildIconButton(
          context,
          tooltip: 'Horizontal Rule',
          icon: Icons.horizontal_rule,
          onPressed: () {
            snippetService.insertHorizontalRule(textController);
            snippetService.refocusEditor(focusNode);
          },
        ),
        _buildIconButton(
          context,
          tooltip: 'Link',
          icon: Icons.link,
          onPressed: () {
            snippetService.insertLink(textController);
            snippetService.refocusEditor(focusNode);
          },
        ),
        _buildIconButton(
          context,
          tooltip: 'Image',
          icon: Icons.image,
          onPressed: () {
            snippetService.insertImage(textController);
            snippetService.refocusEditor(focusNode);
          },
        ),
        _buildIconButton(
          context,
          tooltip: 'Table',
          icon: Icons.table_chart,
          onPressed: () {
            snippetService.insertTable(textController);
            snippetService.refocusEditor(focusNode);
          },
        ),
      ],
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  Widget _buildPopupMenuButton<T>(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required PopupMenuItemBuilder<T> itemBuilder,
    required PopupMenuItemSelected<T> onSelected,
  }) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      itemBuilder: itemBuilder,
      onSelected: onSelected,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  /// Returns the appropriate FontWeight for a header level
  FontWeight _getHeaderWeight(int level) {
    switch (level) {
      case 1:
        return FontWeight.w900;
      case 2:
        return FontWeight.w800;
      case 3:
        return FontWeight.w700;
      case 4:
        return FontWeight.w600;
      case 5:
        return FontWeight.w500;
      case 6:
        return FontWeight.w400;
      default:
        return FontWeight.w400;
    }
  }
}
