// widgets/browser_webview.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../providers/browser_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class BrowserWebView extends StatefulWidget {
  final Function(InAppWebViewController)? onWebViewCreated;

  const BrowserWebView({super.key, this.onWebViewCreated});

  @override
  State<BrowserWebView> createState() => _BrowserWebViewState();
}

class _BrowserWebViewState extends State<BrowserWebView> {
  InAppWebViewController? _controller;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    final browserProvider = context.watch<BrowserProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final currentTab = browserProvider.currentTab;

    if (currentTab.url == 'about:blank') {
      return _buildStartPage(browserProvider, settingsProvider);
    }

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(currentTab.url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            javaScriptCanOpenWindowsAutomatically: false,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            useOnLoadResource: settingsProvider.blockTrackers,
            useShouldOverrideUrlLoading: true,
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            widget.onWebViewCreated?.call(controller);
          },
          onLoadStart: (controller, url) {
            setState(() => _progress = 0);
            currentTab.isLoading = true;
          },
          onProgressChanged: (controller, progress) {
            setState(() => _progress = progress / 100);
          },
          onLoadStop: (controller, url) async {
            currentTab.isLoading = false;
            if (url != null) {
              browserProvider.updateCurrentTab(
                url: url.toString(),
                title: await controller.getTitle() ?? url.toString(),
              );
            }
          },
          onTitleChanged: (controller, title) {
            if (title != null) {
              browserProvider.updateCurrentTab(title: title);
            }
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url;
            if (url != null && settingsProvider.blockTrackers) {
              final urlString = url.toString();
              if (AppConstants.trackerBlocklist.any((domain) => 
                  urlString.contains(domain))) {
                return NavigationActionPolicy.CANCEL;
              }
            }
            return NavigationActionPolicy.ALLOW;
          },
        ),
        if (_progress < 1.0)
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppConstants.primaryColor,
            ),
          ),
      ],
    );
  }

  Widget _buildStartPage(BrowserProvider provider, SettingsProvider settings) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppConstants.backgroundGradient,
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: AppConstants.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withOpacity(0.5),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.language,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    AppConstants.primaryColor,
                    AppConstants.secondaryColor,
                    AppConstants.tertiaryColor,
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Flow Browser',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Workspace: ${provider.currentWorkspace.name}',
                style: TextStyle(
                  color: AppConstants.primaryColor.withOpacity(0.7),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a URL or search query above to start browsing',
                style: TextStyle(
                  color: AppConstants.primaryColor.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  if (settings.vpnEnabled)
                    _buildStatusChip(
                      Icons.shield,
                      'VPN Active',
                      AppConstants.tertiaryColor,
                    ),
                  if (settings.proxyEnabled)
                    _buildStatusChip(
                      Icons.shield,
                      'Proxy Active',
                      Colors.green,
                    ),
                  _buildStatusChip(
                    Icons.lock,
                    'Security: ${settings.securityLevel.toUpperCase()}',
                    AppConstants.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// widgets/browser_tabs.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../utils/constants.dart';

class BrowserTabs extends StatelessWidget {
  const BrowserTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrowserProvider>();
    final workspace = provider.currentWorkspace;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: AppConstants.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: workspace.tabs.length,
              itemBuilder: (context, index) {
                final tab = workspace.tabs[index];
                final isActive = index == provider.activeTabIndex;

                return GestureDetector(
                  onTap: () => provider.switchTab(index),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 150,
                      maxWidth: 200,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.grey.shade800.withOpacity(0.7)
                          : Colors.grey.shade900.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      border: isActive
                          ? const Border(
                              top: BorderSide(
                                color: AppConstants.primaryColor,
                                width: 2,
                              ),
                            )
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.language,
                            size: 16,
                            color: isActive
                                ? AppConstants.primaryColor
                                : AppConstants.primaryColor.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tab.title,
                              style: TextStyle(
                                color: isActive
                                    ? AppConstants.primaryColor
                                    : AppConstants.primaryColor.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (workspace.tabs.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              color: AppConstants.primaryColor.withOpacity(0.6),
                              onPressed: () => provider.closeTab(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppConstants.primaryColor),
            onPressed: () => provider.addTab(),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// widgets/mobile_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../utils/constants.dart';

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrowserProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border(
          top: BorderSide(
            color: AppConstants.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(
                Icons.arrow_back,
                () => provider.goBack(),
                provider.currentTab.canGoBack,
              ),
              _buildNavButton(
                Icons.arrow_forward,
                () => provider.goForward(),
                provider.currentTab.canGoForward,
              ),
              _buildNavButton(
                Icons.refresh,
                () => provider.reload(),
                true,
              ),
              _buildNavButton(
                Icons.home,
                () => provider.goHome(),
                true,
              ),
              _buildNavButton(
                Icons.add,
                () => provider.addTab(),
                true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed, bool enabled) {
    return IconButton(
      icon: Icon(icon),
      color: enabled ? AppConstants.primaryColor : Colors.grey,
      onPressed: enabled ? onPressed : null,
    );
  }
}

// Continue in next artifact due to length...
