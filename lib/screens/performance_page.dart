import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  static const MethodChannel _perfChannel = MethodChannel('com.flow.browser/perf');
  Map<String, dynamic>? _metrics;
  String? _error;
  bool _loading = false;

  Future<void> _fetchMetrics() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _perfChannel.invokeMethod('getMetrics');
      setState(() {
        _metrics = Map<String, dynamic>.from(result as Map);
      });
    } catch (e) {
      setState(() {
        _error = 'Native integration required to fetch system-level metrics.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    try {
      final box = Hive.box('history');
      await box.clear();
      if (!mounted) return; // avoid using context after async gap
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local history cleared')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to clear history')));
    }
  }

  Future<void> _clearCache() async {
    try {
      await _perfChannel.invokeMethod('clearCache');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Requested WebView cache clear')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to clear cache: native platform integration required')));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            if (_metrics != null) ...[
              Text('CPU: ${_metrics!['cpu'] ?? 'n/a'}'),
              Text('Memory: ${_metrics!['memory'] ?? 'n/a'}'),
              Text('WebView memory (approx): ${_metrics!['webviewMemory'] ?? 'n/a'}'),
              const SizedBox(height: 12),
              Text('Active threads: ${_metrics!['threads'] ?? 'n/a'}'),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _clearHistory,
                  child: const Text('Clear Local History'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _clearCache,
                  child: const Text('Clear WebView Cache'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Notes'),
            const SizedBox(height: 8),
            const Text('• Native platform methods are required to report exact CPU/RAM and to clear WebView cache reliably. If you want, we can implement the platform channels for Windows/macOS/Linux/Android/iOS.'),
          ],
        ),
      ),
    );
  }
}
