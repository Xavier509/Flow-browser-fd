import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_modal.dart';
import '../providers/browser_provider.dart';
import 'todo_editor.dart';

class TodosPanel extends StatefulWidget {
  final VoidCallback? onClose;
  const TodosPanel({super.key, this.onClose});

  @override
  State<TodosPanel> createState() => _TodosPanelState();
}

class _TodosPanelState extends State<TodosPanel> {
  final TextEditingController _searchController = TextEditingController();
  late Box _todosBox;

  @override
  void initState() {
    super.initState();
    _todosBox = Hive.box('todos');
  }

  List<Map<String, dynamic>> _loadItems() {
    final raw = _todosBox.values.toList().reversed.toList().cast<dynamic>();
    return raw.map((v) {
      final m = Map<String, dynamic>.from(v as Map);
      return {
        'title': m['title'] ?? m['text'] ?? '',
        'desc': m['desc'] ?? '',
        'done': m['done'] ?? false,
        'due': m['due'],
        'ts': m['ts'] ?? m['created_at'] ?? DateTime.now().toIso8601String(),
      };
    }).where((it) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return (it['title'] as String).toLowerCase().contains(q) || (it['desc'] as String).toLowerCase().contains(q);
    }).toList();
  }

  void _openEditor({Map<String, dynamic>? initial, int? key}) async {
    await Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (ctx) {
      return TodoEditor(
        initial: initial,
        onSave: (todo) async {
          if (key != null) {
            _todosBox.put(key, todo);
          } else {
            _todosBox.add(todo);
          }

          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == null) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign In to Sync'),
                content: const Text('You are not signed in. Would you like to sign in to sync to-dos to the cloud?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (c) => AuthModal(onClose: () => Navigator.pop(c)),
                      );
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            );
            return;
          }

          try {
            final provider = context.read<BrowserProvider>();
            provider.upsertTodoToSupabase({'text': todo['title'], 'done': todo['done'] ?? false, 'ts': todo['ts']});
          } catch (_) {}
        },
        onDelete: () {
          if (key != null) _todosBox.delete(key);
        },
      );
    }));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = _loadItems();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ListTile(
            title: const Text('To-dos'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.add), onPressed: () => _openEditor()),
              IconButton(icon: const Icon(Icons.open_in_new), onPressed: () async {
                const url = 'https://example.com/docs/todos';
                final provider = context.read<BrowserProvider>();
                provider.addTab();
                provider.navigateToUrl(url);
              }),
              IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search to-dos...'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No to-dos yet'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final e = items[index];
                      final keyAt = _todosBox.length - 1 - index;
                      return CheckboxListTile(
                        value: e['done'] as bool,
                        title: Text(e['title'] ?? ''),
                        subtitle: Text(e['ts'] ?? ''),
                        onChanged: (v) async {
                          final updated = {'title': e['title'], 'desc': e['desc'], 'done': v ?? false, 'due': e['due'], 'ts': e['ts']};
                          _todosBox.put(keyAt, updated);

                          final userId = Supabase.instance.client.auth.currentUser?.id;
                          if (userId == null) {
                            // Prompt to sign in to enable remote sync
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Sign In to Sync'),
                                content: const Text('You are not signed in. Would you like to sign in to sync to-dos to the cloud?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (c) => AuthModal(onClose: () => Navigator.pop(c)),
                                      );
                                    },
                                    child: const Text('Sign In'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            try {
                              final provider = context.read<BrowserProvider>();
                              provider.upsertTodoToSupabase({'text': updated['title'], 'done': updated['done'] ?? false, 'ts': updated['ts']});
                            } catch (_) {}
                          }

                          setState(() {});
                        },
                        secondary: IconButton(icon: const Icon(Icons.edit), onPressed: () => _openEditor(initial: e, key: keyAt)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
