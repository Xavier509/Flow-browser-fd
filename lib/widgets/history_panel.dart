import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';

class HistoryPanel extends StatefulWidget {
  final VoidCallback? onClose;
  const HistoryPanel({super.key, this.onClose});

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
  final TextEditingController _searchController = TextEditingController();

  Box get _historyBox => Hive.box('history');

  List<Map<String, dynamic>> _loadItems() {
    final raw = _historyBox.values.toList().reversed.toList().cast<dynamic>();
    final items = raw.map((v) {
      final m = Map<String, dynamic>.from(v as Map);
      return {
        'url': m['url'] ?? '',
        'timestamp': m['timestamp'] ?? m['ts'] ?? '',
        'query': m['query'] ?? '',
      };
    }).toList();

    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((it) => (it['url'] as String).toLowerCase().contains(q) || (it['query'] as String).toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BrowserProvider>(context, listen: false);
    final recs = provider.getRecommendations(limit: 6);
    final items = _loadItems();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          ListTile(
            title: const Text('History'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () async {
                    try {
                      final messenger = ScaffoldMessenger.of(context);
                      await provider.syncHistoryFromSupabase();
                      if (!mounted) return;
                      messenger.showSnackBar(const SnackBar(content: Text('History synced')));
                      setState(() {});
                    } catch (_) {}
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    _historyBox.clear();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History cleared')));
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          if (recs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recommended searches', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: recs.map((r) => ActionChip(label: Text(r), onPressed: () => provider.navigateToUrl(r))).toList(),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search history...'),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const Divider(),

          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final e = items[index];
                return ListTile(
                  title: Text(e['url'] ?? ''),
                  subtitle: Text(e['timestamp'] ?? ''),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.open_in_new), onPressed: () async {
                      final url = e['url'] ?? '';
                      try {
                        final provider = context.read<BrowserProvider>();
                        provider.addTab();
                        provider.navigateToUrl(url);
                      } catch (_) {}
                    }),
                    IconButton(icon: const Icon(Icons.copy), onPressed: () {
                      Clipboard.setData(ClipboardData(text: e['url'] ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied URL')));
                    }),
                  ]),
                  onTap: () {
                    provider.navigateToUrl(e['url'] ?? '');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
