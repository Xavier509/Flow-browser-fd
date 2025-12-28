import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class SourceViewerDialog extends StatefulWidget {
  final String title;
  final String url;
  final String source;

  const SourceViewerDialog({
    super.key,
    required this.title,
    required this.url,
    required this.source,
  });

  @override
  State<SourceViewerDialog> createState() => _SourceViewerDialogState();
}

class _SourceViewerDialogState extends State<SourceViewerDialog> {
  late TextEditingController _sourceController;
  bool _isHtmlView = true;

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController(text: widget.source);
  }

  @override
  void dispose() {
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppConstants.surfaceColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.url,
                        style: TextStyle(
                          color: AppConstants.primaryColor.withAlpha((0.7 * 255).round()),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // View toggle
                    IconButton(
                      icon: Icon(
                        _isHtmlView ? Icons.code : Icons.web,
                        color: AppConstants.primaryColor,
                      ),
                      tooltip: _isHtmlView ? 'View as Code' : 'View as HTML',
                      onPressed: () => setState(() => _isHtmlView = !_isHtmlView),
                    ),
                    // Copy button
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppConstants.primaryColor),
                      tooltip: 'Copy Source',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.source));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Source copied to clipboard')),
                        );
                      },
                    ),
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, color: AppConstants.primaryColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            // Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _isHtmlView ? _formatHtml(widget.source) : widget.source,
                    style: TextStyle(
                      color: _isHtmlView ? Colors.white : AppConstants.primaryColor,
                      fontFamily: _isHtmlView ? 'monospace' : null,
                      fontSize: _isHtmlView ? 12 : 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHtml(String html) {
    // Basic HTML formatting for better readability
    return html
        .replaceAll('<', '\n<')
        .replaceAll('>', '>\n')
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .join('\n');
  }
}