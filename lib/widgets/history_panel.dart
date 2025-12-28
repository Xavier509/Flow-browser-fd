import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BrowserProvider>(context);
    final Box historyBox = Hive.box('history');
    final List items = historyBox.values.toList().reversed.toList();

    final recs = provider.getRecommendations(limit: 6);
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
                      await provider.syncHistoryFromSupabase();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History synced')));
                    } catch (_) {}
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    historyBox.clear();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History cleared')));
                  },
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
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final e = Map<String, dynamic>.from(items[index]);
                return ListTile(
                  title: Text(e['url'] ?? ''),
                  subtitle: Text(e['timestamp'] ?? ''),
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
