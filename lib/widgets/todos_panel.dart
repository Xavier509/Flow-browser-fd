import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';

class TodosPanel extends StatefulWidget {
  const TodosPanel({super.key});

  @override
  State<TodosPanel> createState() => _TodosPanelState();
}

class _TodosPanelState extends State<TodosPanel> {
  final TextEditingController _controller = TextEditingController();
  late Box _todosBox;

  @override
  void initState() {
    super.initState();
    _todosBox = Hive.box('todos');
  }

  @override
  Widget build(BuildContext context) {
    final items = _todosBox.values.toList().reversed.toList();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const ListTile(title: Text('To-dos')),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'New to-do...'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_controller.text.trim().isEmpty) return;
                  final todo = {'text': _controller.text.trim(), 'done': false, 'ts': DateTime.now().toIso8601String()};
                  _todosBox.add(todo);
                  // Sync to Supabase if logged in
                  try {
                    final provider = context.read<BrowserProvider>();
                    provider.upsertTodoToSupabase(todo);
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
                final key = _todosBox.keyAt(_todosBox.length - 1 - index);
                return CheckboxListTile(
                  value: e['done'] as bool,
                  title: Text(e['text'] ?? ''),
                  subtitle: Text(e['ts'] ?? ''),
                  onChanged: (v) {
                    final updated = {'text': e['text'], 'done': v ?? false, 'ts': e['ts']};
                    _todosBox.put(key, updated);
                    try {
                      // ignore: avoid_dynamic_calls
                      final provider = context.read<dynamic>();
                      provider.upsertTodoToSupabase(updated);
                    } catch (_) {}
                    setState(() {});
                  },
                  secondary: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      _todosBox.delete(key);
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
