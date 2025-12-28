import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class TodoEditor extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback? onDelete;

  const TodoEditor({super.key, this.initial, required this.onSave, this.onDelete});

  @override
  State<TodoEditor> createState() => _TodoEditorState();
}

class _TodoEditorState extends State<TodoEditor> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _due;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _titleCtrl.text = widget.initial!['title'] ?? widget.initial!['text'] ?? '';
      _descCtrl.text = widget.initial!['desc'] ?? '';
      _done = widget.initial!['done'] ?? false;
      if (widget.initial!['due'] != null) {
        try {
          _due = DateTime.parse(widget.initial!['due']);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: now.subtract(const Duration(days: 3650)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _due = picked);
  }

  void _save() {
    final todo = {
      'title': _titleCtrl.text.trim(),
      'desc': _descCtrl.text.trim(),
      'done': _done,
      'due': _due?.toIso8601String(),
      'ts': widget.initial?['ts'] ?? DateTime.now().toIso8601String(),
    };
    widget.onSave(todo);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'New To-do' : 'Edit To-do'),
        centerTitle: true,
        actions: [
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                widget.onDelete?.call();
                Navigator.of(context).maybePop();
              },
            ),
          ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white), child: const Text('Save')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            TextField(controller: _descCtrl, decoration: const InputDecoration(hintText: 'Details...'), keyboardType: TextInputType.multiline, maxLines: null),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(value: _done, onChanged: (v) => setState(() => _done = v ?? false)),
                const Text('Completed'),
                const SizedBox(width: 12),
                TextButton.icon(onPressed: _pickDue, icon: const Icon(Icons.calendar_today), label: Text(_due == null ? 'Set due' : DateFormat.yMd().format(_due!))),
              ],
            ),
            const Spacer(),
            Align(alignment: Alignment.centerLeft, child: Text('Last edited: ${DateFormat.yMd().add_jm().format(DateTime.parse(widget.initial?['ts'] ?? DateTime.now().toIso8601String()))}', style: const TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}
