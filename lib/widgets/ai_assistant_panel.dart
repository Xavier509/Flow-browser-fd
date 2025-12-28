import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AIAssistantPanel extends StatelessWidget {
  final WebViewController? webViewController;
  final VoidCallback onClose;
  final bool isMobile;

  const AIAssistantPanel({
    super.key,
    this.webViewController,
    required this.onClose,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 300,
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('AI Assistant', style: TextStyle(fontSize: 18)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
          const Expanded(
            child: Center(
              child: Text('AI features coming soon...'),
            ),
          ),
        ],
      ),
    );
  }
}