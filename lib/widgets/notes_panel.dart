import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../providers/browser_provider.dart';
import 'note_editor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_modal.dart';

class NotesPanel extends StatefulWidget {
  final VoidCallback? onClose;
  const NotesPanel({super.key, this.onClose});

  @override
  State<NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends State<NotesPanel> {
  final TextEditingController _searchController = TextEditingController();
  late Box _notesBox;

  @override
  void initState() {
    super.initState();
    _notesBox = Hive.box('notes');
  }

  List<Map<String, dynamic>> _loadItems() {
    final raw = _notesBox.values.toList().reversed.toList().cast<dynamic>();
    final List<Map<String, dynamic>> items = raw.map((v) {
      final m = Map<String, dynamic>.from(v as Map);
      // Normalize old structure where 'text' was used
      if (!m.containsKey('title') && m.containsKey('text')) {
        final txt = m['text'] ?? '';
        final lines = (txt as String).split('\n');
        final title = lines.isNotEmpty ? (lines.first.length > 40 ? lines.first.substring(0, 40) + '...' : lines.first) : '';
        return {'title': title, 'content': txt, 'ts': m['ts'] ?? m['created_at'] ?? DateTime.now().toIso8601String()};
      }
      return {'title': m['title'] ?? '', 'content': m['content'] ?? m['text'] ?? '', 'ts': m['ts'] ?? m['created_at'] ?? DateTime.now().toIso8601String()};
    }).toList();

    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((it) => (it['title'] as String).toLowerCase().contains(q) || (it['content'] as String).toLowerCase().contains(q)).toList();
  }

  void _openEditor({Map<String, dynamic>? initial, int? key}) async {
    // push full screen editor
    await Navigator.of(context).push<bool?>(MaterialPageRoute(fullscreenDialog: true, builder: (ctx) {
      return NoteEditor(
        initial: initial,
        onSave: (note) async {
          if (key != null) {
            _notesBox.put(key, note);
          } else {
            _notesBox.add(note);
          }

          // If user is not logged in, prompt to sign in to enable remote sync
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == null) {
            // show prompt, don't block local save
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign In to Sync'),
                content: const Text('You are not signed in. Would you like to sign in to sync notes to the cloud?'),
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
            // sync: send title + content as text to avoid schema mismatch
            provider.upsertNoteToSupabase({'text': '${note['title']}\n\n${note['content']}', 'ts': note['ts']});
          } catch (_) {}
        },
        onDelete: () {
          if (key != null) _notesBox.delete(key);
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
            title: const Text('Notes'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.add), onPressed: () => _openEditor()),
              IconButton(icon: const Icon(Icons.open_in_new), onPressed: () async {
                const url = 'https://example.com/docs/notes';
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
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search notes...'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No notes yet'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final e = items[index];
                      // compute Hive key for this entry
                      final keyAt = _notesBox.length - 1 - index;
                      return ListTile(
                        title: Text(e['title'] ?? ''),
                        subtitle: Text((e['content'] as String).split('\n').take(2).join('\n')),
                        onTap: () => _openEditor(initial: e, key: keyAt),
                        trailing: IconButton(icon: const Icon(Icons.open_in_new), onPressed: () => _openEditor(initial: e, key: keyAt)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
