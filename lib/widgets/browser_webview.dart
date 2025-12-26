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
  String? _lastLoadedUrl;
  String? _lastTabId;
  final Map<String, String> _tabCache = {}; // Cache for tab URLs
  final Map<String, String> _titleCache = {}; // Cache for tab titles

  @override
  void didUpdateWidget(BrowserWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final browserProvider = context.read<BrowserProvider>();
    final currentTab = browserProvider.currentTab;
    
    // Load new URL if:
    // 1. Tab changed (different tab ID)
    // 2. URL changed for current tab
    // 3. URL is not about:blank
    final tabChanged = _lastTabId != currentTab.id;
    final urlChanged = currentTab.url != _lastLoadedUrl;
    
    if (_controller != null && (tabChanged || urlChanged) && currentTab.url != 'about:blank') {
      // Use cache if available for instant switching
      if (tabChanged && _tabCache.containsKey(currentTab.id)) {
        _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(_tabCache[currentTab.id]!)));
        _lastLoadedUrl = _tabCache[currentTab.id];
      } else {
        _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(currentTab.url)));
        _lastLoadedUrl = currentTab.url;
      }
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
            // Performance optimizations
            cacheEnabled: true,
            domStorageEnabled: true,
            databaseEnabled: true,
            hardwareAcceleration: true,
            useWideViewPort: true,
            loadWithOverviewMode: true,
            supportZoom: false,
            builtInZoomControls: false,
            displayZoomControls: false,
            useOnRenderProcessGone: true,
            safeBrowsingEnabled: true,
            disableDefaultErrorPage: true,
            verticalScrollBarEnabled: false,
            horizontalScrollBarEnabled: false,
            overScrollMode: OverScrollMode.IF_CONTENT_SCROLLS,
            scrollBarStyle: ScrollBarStyle.SCROLLBARS_OUTSIDE_OVERLAY,
            scrollBarFadeDuration: 0,
            // Network optimizations
            resourceCustomSchemes: [],
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            _lastLoadedUrl = context.read<BrowserProvider>().currentTab.url;
            widget.onWebViewCreated?.call(controller);
          },
          onLoadStart: (controller, url) {
            setState(() => _progress = 0);
            currentTab.isLoading = true;
            if (url != null) {
              browserProvider.updateCurrentTab(url: url.toString());
            }
          },
          onProgressChanged: (controller, progress) {
            setState(() => _progress = progress / 100);
          },
          onLoadStop: (controller, url) async {
            currentTab.isLoading = false;
            if (url != null) {
              final title = await controller.getTitle() ?? url.toString();
              browserProvider.updateCurrentTab(
                url: url.toString(),
                title: title,
              );
              // Cache the URL and title for instant switching
              _tabCache[currentTab.id] = url.toString();
              _titleCache[currentTab.id] = title;
            }
            setState(() => _progress = 1.0);
          },
          onTitleChanged: (controller, title) {
            if (title != null) {
              browserProvider.updateCurrentTab(title: title);
              // Cache the title for instant switching
              _titleCache[currentTab.id] = title;
            }
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url;
            if (url != null) {
              final urlString = url.toString();
              browserProvider.updateCurrentTab(url: urlString);
              
              if (settingsProvider.blockTrackers) {
                if (AppConstants.trackerBlocklist.any((domain) => 
                    urlString.contains(domain))) {
                  return NavigationActionPolicy.CANCEL;
                }
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
                      color: AppConstants.primaryColor.withOpacity(0.35),
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
                  color: AppConstants.primaryColor.withOpacity(0.75),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a URL or search query above to start browsing',
                style: TextStyle(
                  color: AppConstants.primaryColor.withOpacity(0.55),
                  fontSize: 13,
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
