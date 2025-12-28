import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class NoteEditor extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback? onDelete;

  const NoteEditor({super.key, this.initial, required this.onSave, this.onDelete});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  String _prevContent = '';

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _titleCtrl.text = widget.initial!['title'] ?? '';
      _contentCtrl.text = widget.initial!['content'] ?? widget.initial!['text'] ?? '';
    }
    _prevContent = _contentCtrl.text;
    _contentCtrl.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.removeListener(_onContentChanged);
    _contentCtrl.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _insertBullet() {
    final sel = _contentCtrl.selection;
    final text = _contentCtrl.text;
    const insert = '- ';
    final newText = text.replaceRange(sel.start, sel.end, insert);
    final newPos = sel.start + insert.length;
    _contentCtrl.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newPos));
    _contentFocusNode.requestFocus();
  }

  void _save() {
    final note = {
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
      'ts': widget.initial?['ts'] ?? DateTime.now().toIso8601String(),
    };
    widget.onSave(note);
    Navigator.of(context).maybePop();
  }

  void _onContentChanged() {
    final newText = _contentCtrl.text;
    final sel = _contentCtrl.selection;

    try {
      // Handle Enter insertion: when a newline is added
      if (newText.length > _prevContent.length) {
        final pos = sel.baseOffset;
        if (pos > 0 && newText[pos - 1] == '\n') {
          final insertionIndex = pos - 1;
          int lineStart = _prevContent.lastIndexOf('\n', insertionIndex - 1);
          lineStart = lineStart == -1 ? 0 : lineStart + 1;
          int lineEnd = _prevContent.indexOf('\n', insertionIndex - 1);
          if (lineEnd == -1) lineEnd = _prevContent.length;
          final line = _prevContent.substring(lineStart, lineEnd);

          if (line.startsWith('- ')) {
            if (line.trim() == '-' || line.trim() == '- ') {
              // Remove the bullet from the previous line and keep the newline
              final removeStart = lineStart;
              final removeEnd = lineStart + 2;
              final updated = newText.replaceRange(removeStart, removeEnd, '');
              final newOffset = (pos - 2).clamp(0, updated.length);
              _contentCtrl.value = TextEditingValue(text: updated, selection: TextSelection.collapsed(offset: newOffset));
            } else {
              // Continue the bullet on the next line
              final updated = newText.replaceRange(pos, pos, '- ');
              final newOffset = (pos + 2).clamp(0, updated.length);
              _contentCtrl.value = TextEditingValue(text: updated, selection: TextSelection.collapsed(offset: newOffset));
            }
          }
        }
      }

      // Handle deletion/backspace leaving an empty bullet line -> remove the '- '
      if (newText.length < _prevContent.length) {
        final pos = sel.baseOffset;
        int lineStart = newText.lastIndexOf('\n', pos - 1);
        lineStart = lineStart == -1 ? 0 : lineStart + 1;
        int lineEnd = newText.indexOf('\n', pos);
        if (lineEnd == -1) lineEnd = newText.length;
        final line = newText.substring(lineStart, lineEnd);
        if (line.startsWith('- ') && line.trim() == '-') {
          final updated = newText.replaceRange(lineStart, lineStart + 2, '');
          final newOffset = (pos - 2).clamp(0, updated.length);
          _contentCtrl.value = TextEditingValue(text: updated, selection: TextSelection.collapsed(offset: newOffset));
        }
      }
    } catch (_) {
      // Safely ignore unexpected edge cases
    } finally {
      _prevContent = _contentCtrl.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'New Note' : 'Edit Note'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            onPressed: _insertBullet,
            tooltip: 'Insert bullet',
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                widget.onDelete?.call();
                Navigator.of(context).maybePop();
              },
            ),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                decoration: const InputDecoration(hintText: 'Write your notes here...', border: InputBorder.none),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                focusNode: _contentFocusNode,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Last edited: ${DateFormat.yMd().add_jm().format(DateTime.parse(widget.initial?['ts'] ?? DateTime.now().toIso8601String()))}', style: const TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
