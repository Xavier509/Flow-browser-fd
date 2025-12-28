// widgets/browser_webview.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../providers/browser_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class BrowserWebView extends StatefulWidget {
  final Function(WebViewController)? onWebViewCreated;

  const BrowserWebView({super.key, this.onWebViewCreated});

  @override
  State<BrowserWebView> createState() => _BrowserWebViewState();
}

class _BrowserWebViewState extends State<BrowserWebView> {
  WebViewController? _controller;
  double _progress = 0;
  String? _lastLoadedUrl;
  String? _lastTabId;
  String? _webviewError;
  final Map<String, String> _tabCache = {}; // Cache for tab URLs
  final Map<String, String> _titleCache = {}; // Cache for tab titles

  Future<void> _tryInitController() async {
    // Try a few times because platform init can be flaky on some Windows setups
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() {
                  _progress = 0;
                  _webviewError = null;
                });
                final provider = context.read<BrowserProvider>();
                provider.currentTab.isLoading = true;
                provider.updateCurrentTab(url: url);
              },
              onProgress: (int progress) {
                setState(() => _progress = progress / 100);
              },
              onPageFinished: (String url) {
                setState(() => _progress = 1.0);
                final provider = context.read<BrowserProvider>();
                provider.currentTab.isLoading = false;
                // Cache the URL
                _tabCache[provider.currentTab.id] = url;
              },
              onWebResourceError: (WebResourceError error) {
                setState(() {
                  _webviewError = error.description ?? error.toString();
                });
                debugPrint('WebView error: ${error.description}');
              },
              onNavigationRequest: (request) => NavigationDecision.navigate,
            ),
          );
        // notify parent that controller is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onWebViewCreated?.call(_controller!);
        });
        // successful init
        return;
      } catch (e) {
        debugPrint('WebView init attempt ${attempt + 1} failed: $e');
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
        _controller = null;
      }
    }

    // After retries, surface friendly error with guidance
    setState(() {
      _webviewError = 'WebView platform unavailable after multiple attempts. Likely causes: 1) `flutter pub get` failed or an invalid package in `pubspec.yaml`, or 2) the Microsoft Edge WebView2 runtime is not installed on Windows. Try installing WebView2, running `flutter pub get`, or use the "Open externally" option.';
    });
  }

  @override
  void initState() {
    super.initState();
    _tryInitController();
  }

  @override
  void didUpdateWidget(BrowserWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final browserProvider = context.read<BrowserProvider>();
    final currentTab = browserProvider.currentTab;
    
    final tabChanged = _lastTabId != currentTab.id;
    final urlChanged = currentTab.url != _lastLoadedUrl;
    
    if (_controller != null && (tabChanged || urlChanged) && currentTab.url != 'about:blank') {
      _controller!.loadRequest(Uri.parse(currentTab.url));
      _lastLoadedUrl = currentTab.url;
      _lastTabId = currentTab.id;
      
      // Update title from cache if available
      if (tabChanged && _titleCache.containsKey(currentTab.id)) {
        currentTab.title = _titleCache[currentTab.id]!;
      }
    } else if (tabChanged) {
      _lastTabId = currentTab.id;
      _lastLoadedUrl = currentTab.url;
    }
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = context.watch<BrowserProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final currentTab = browserProvider.currentTab;

    if (currentTab.url == 'about:blank') {
      return _buildStartPage(browserProvider, settingsProvider);
    }

    // Initialize webview with current URL on first load
    if (_lastLoadedUrl == null && _controller != null) {
      _controller!.loadRequest(Uri.parse(currentTab.url));
      _lastLoadedUrl = currentTab.url;
    }

    // If the webview reported an error, show a friendly error UI with retry
    if (_webviewError != null) {
      final showUrl = _lastLoadedUrl ?? (currentTab.url == 'about:blank' ? null : currentTab.url);
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text(
                'WebView Error',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 480,
                child: Text(
                  'WebView platform is unavailable. This usually means the platform implementation for webview_flutter is not available or the Microsoft Edge WebView2 runtime is not installed on Windows. You can try installing WebView2, open the URL in your system browser, or retry the in-app WebView.',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      setState(() => _webviewError = null);
                      await _tryInitController();
                      if (_controller != null && _lastLoadedUrl != null) {
                        _controller!.loadRequest(Uri.parse(_lastLoadedUrl!));
                      }
                    },
                    child: const Text('Retry'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      const url = 'https://developer.microsoft.com/en-us/microsoft-edge/webview2/#download-section';
                      try { await launchUrlString(url); } catch (_) {}
                    },
                    child: const Text('Install WebView2'),
                  ),
                  if (showUrl != null) ...[
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final provider = context.read<BrowserProvider>();
                          provider.addTab();
                          provider.navigateToUrl(showUrl);
                        } catch (_) {}
                      },
                      child: const Text('Open in Flow'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await launchUrlString(showUrl);
                        } catch (_) {}
                      },
                      child: const Text('Open externally'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(
          controller: _controller ?? WebViewController(),
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
                      color: AppConstants.primaryColor.withAlpha((0.35 * 255).round()),
                      blurRadius: 30,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.language,
                  size: 44,
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
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Workspace: ${provider.currentWorkspace.name}',
                style: TextStyle(
                  color: AppConstants.primaryColor.withAlpha((0.75 * 255).round()),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a URL or search query above to start browsing',
                style: TextStyle(
                  color: AppConstants.primaryColor.withAlpha((0.55 * 255).round()),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Recommended searches on the start page
              Builder(builder: (ctx) {
                final recs = context.read<BrowserProvider>().getRecommendations(limit: 6);
                return Column(
                  children: [
                    if (recs.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                          child: Text('Recommended for you', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: recs.map((r) => ActionChip(label: Text(r), onPressed: () => context.read<BrowserProvider>().navigateToUrl(r))).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                );
              }),
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
        color: color.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),

      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color.withAlpha((0.85 * 255).round()), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
