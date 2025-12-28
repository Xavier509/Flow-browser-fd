import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';

class NotesPanel extends StatefulWidget {
  const NotesPanel({super.key});

  @override
  State<NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends State<NotesPanel> {
  final TextEditingController _controller = TextEditingController();
  late Box _notesBox;

  @override
  void initState() {
    super.initState();
    _notesBox = Hive.box('notes');
  }

  @override
  Widget build(BuildContext context) {
    final items = _notesBox.values.toList().reversed.toList();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const ListTile(title: Text('Notes')),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'New note...'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_controller.text.trim().isEmpty) return;
                  final note = {'text': _controller.text.trim(), 'ts': DateTime.now().toIso8601String()};
                  _notesBox.add(note);
                  // Sync to Supabase if logged in
                  try {
                    final provider = context.read<BrowserProvider>();
                    provider.upsertNoteToSupabase(note);
                  } catch (_) {}
                  _controller.clear();
                  setState(() {});
                },
              )
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final e = Map<String, dynamic>.from(items[index]);
                return ListTile(
                  title: Text(e['text'] ?? ''),
                  subtitle: Text(e['ts'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      final key = _notesBox.keyAt(_notesBox.length - 1 - index);
                      _notesBox.delete(key);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
