import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/browser_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class BrowserHeader extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onAITap;
  final VoidCallback onWorkspaceTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onAuthTap;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onNotesTap;
  final VoidCallback? onTodosTap;
  final bool isMobile;
  final WebViewController? webViewController;

  const BrowserHeader({
    super.key,
    this.onMenuTap,
    required this.onBookmarkTap,
    required this.onAITap,
    required this.onWorkspaceTap,
    required this.onSettingsTap,
    required this.onAuthTap,
    this.onHistoryTap,
    this.onNotesTap,
    this.onTodosTap,
    required this.isMobile,
    this.webViewController,
  });

  @override
  State<BrowserHeader> createState() => _BrowserHeaderState();
}

class _BrowserHeaderState extends State<BrowserHeader> {
  final TextEditingController _urlController = TextEditingController();
  bool _showMoreOptions = false;
  bool _isLoadingUrl = false;
  String _lastSetUrl = '';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BrowserHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the URL changed externally and text field is not focused
    final newUrl = context.read<BrowserProvider>().urlInput;
    if (_lastSetUrl != newUrl && !_urlController.selection.isValid) {
      _urlController.text = newUrl;
      _lastSetUrl = newUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = context.watch<BrowserProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    // Only set initial URL if controller is empty or needs updating
    if (_urlController.text.isEmpty && browserProvider.urlInput.isNotEmpty) {
      _urlController.text = browserProvider.urlInput;
      _lastSetUrl = browserProvider.urlInput;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 8 : 16,
        vertical: widget.isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withAlpha((0.6 * 255).round()),
        border: Border(
          bottom: BorderSide(
            color: AppConstants.primaryColor.withAlpha((0.3 * 255).round()),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Mobile menu button
          if (widget.isMobile && widget.onMenuTap != null)
            IconButton(
              icon: const Icon(Icons.menu, color: AppConstants.primaryColor),
              onPressed: widget.onMenuTap,
            ),
          
          // Logo
          _buildLogo(),
          
          const SizedBox(width: 12),
          
          // Workspace indicator (desktop/tablet)
          if (!widget.isMobile) _buildWorkspaceButton(browserProvider),
          
          const SizedBox(width: 12),
          
          // Navigation controls (desktop/tablet)
          if (!widget.isMobile) _buildNavigationControls(browserProvider),
          
          const SizedBox(width: 12),
          
          // URL bar
          Expanded(child: _buildUrlBar(browserProvider, settingsProvider)),
          
          const SizedBox(width: 12),
          
          // Action buttons
          if (!widget.isMobile) ..._buildDesktopActions(browserProvider),
          // History / Notes / Todos icons
          if (!widget.isMobile) ...[
            IconButton(
              icon: const Icon(Icons.history, color: AppConstants.primaryColor),
              onPressed: widget.onHistoryTap,
            ),
            IconButton(
              icon: const Icon(Icons.note_alt, color: AppConstants.primaryColor),
              onPressed: widget.onNotesTap,
            ),
            IconButton(
              icon: const Icon(Icons.checklist_rtl, color: AppConstants.primaryColor),
              onPressed: widget.onTodosTap,
            ),
          ],
          
          // Mobile more options
          if (widget.isMobile)
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppConstants.primaryColor),
              onPressed: () => setState(() => _showMoreOptions = !_showMoreOptions),
            ),
          
          // User menu (desktop/tablet)
          if (!widget.isMobile) _buildUserMenu(authProvider),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: widget.isMobile ? 32 : 40,
          height: widget.isMobile ? 32 : 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppConstants.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withAlpha((0.5 * 255).round()),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.language,
            color: Colors.white,
            size: widget.isMobile ? 18 : 24,
          ),
        ),
        if (!widget.isMobile) ...[
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) => AppConstants.primaryGradient.createShader(bounds),
            child: const Text(
              'Flow',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBookmarksButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withAlpha((0.5 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Tooltip(
        message: 'Bookmarks',
        child: IconButton(
          icon: const Icon(Icons.bookmarks),
          color: AppConstants.primaryColor,
          iconSize: 20,
          onPressed: widget.onBookmarkTap,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }

  Widget _buildWorkspaceButton(BrowserProvider provider) {
    final workspace = provider.currentWorkspace;
    final icon = _getWorkspaceIcon(workspace.icon);
    
    return InkWell(
      onTap: widget.onWorkspaceTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Color(workspace.color).withAlpha((0.2 * 255).round()),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(workspace.color).withAlpha((0.3 * 255).round()),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Text(
              workspace.name,
              style: const TextStyle(
                color: AppConstants.primaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls(BrowserProvider provider) {
    return Row(
      children: [
        _buildNavButton(
          Icons.arrow_back,
          () async {
            if (widget.webViewController != null) {
              if (await widget.webViewController!.canGoBack()) {
                await widget.webViewController!.goBack();
                // Force URL update after navigation
                Future.delayed(const Duration(milliseconds: 100), () async {
                  final currentUrl = await widget.webViewController!.currentUrl();
                  if (currentUrl != null && mounted) {
                    provider.updateCurrentTab(url: currentUrl.toString());
                  }
                });
              }
            } else {
              provider.goBack();
            }
          },
          true,
        ),
        const SizedBox(width: 4),
        _buildNavButton(
          Icons.arrow_forward,
          () async {
            if (widget.webViewController != null) {
              if (await widget.webViewController!.canGoForward()) {
                await widget.webViewController!.goForward();
                // Force URL update after navigation
                Future.delayed(const Duration(milliseconds: 100), () async {
                  final currentUrl = await widget.webViewController!.currentUrl();
                  if (currentUrl != null && mounted) {
                    provider.updateCurrentTab(url: currentUrl.toString());
                  }
                });
              }
            } else {
              provider.goForward();
            }
          },
          true,
        ),
        const SizedBox(width: 4),
        _buildNavButton(
          Icons.refresh,
          () async {
            if (widget.webViewController != null) {
              await widget.webViewController!.reload();
              // Force URL update after reload
              Future.delayed(const Duration(milliseconds: 100), () async {
                final currentUrl = await widget.webViewController!.currentUrl();
                if (currentUrl != null && mounted) {
                  provider.updateCurrentTab(url: currentUrl.toString());
                }
              });
            } else {
              provider.reload();
            }
          },
          true,
        ),
        const SizedBox(width: 4),
        _buildNavButton(
          Icons.home,
          () => provider.goHome(),
          true,
        ),
        const SizedBox(width: 4),
        _buildBookmarksButton(),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed, bool enabled) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withAlpha((0.35 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: enabled ? AppConstants.primaryColor : Colors.grey,
        iconSize: 20,
        onPressed: enabled ? onPressed : null,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _buildUrlBar(BrowserProvider browserProvider, SettingsProvider settingsProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withAlpha((0.5 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.primaryColor.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search,
              color: AppConstants.primaryColor,
              size: 18,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.isMobile ? 'URL...' : 'Enter URL or search...',
                hintStyle: TextStyle(
                  color: AppConstants.primaryColor.withAlpha((0.3 * 255).round()),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                _lastSetUrl = value;
                browserProvider.setUrlInput(value);
              },
              onSubmitted: (value) async {
                // Show instant loading feedback
                setState(() => _isLoadingUrl = true);
                try {
                  browserProvider.navigateToUrl(value, settingsProvider.searchEngine);
                  // If we have a controller, load immediately for instant feedback
                  final cur = browserProvider.currentTab.url;
                  if (widget.webViewController != null && cur.isNotEmpty && cur != 'about:blank') {
                    try {
                      await widget.webViewController!.loadRequest(Uri.parse(cur));
                    } catch (_) {}
                  }
                } finally {
                  // Reset loading state after a short delay to show the transition
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) setState(() => _isLoadingUrl = false);
                  });
                }
              },
            ),
          ),
          // Loading indicator
          if (_isLoadingUrl)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                ),
              ),
            ),
          if (settingsProvider.vpnEnabled || settingsProvider.proxyEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  if (settingsProvider.vpnEnabled)
                    const Icon(
                      Icons.shield,
                      color: AppConstants.tertiaryColor,
                      size: 16,
                    ),
                  if (settingsProvider.proxyEnabled) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.shield,
                      color: Colors.green,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDesktopActions(BrowserProvider provider) {
    return [
      Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFa855f7),
              Color(0xFFec4899),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFa855f7).withAlpha((0.3 * 255).round()),
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.auto_awesome),
          color: Colors.white,
          iconSize: 20,
          onPressed: widget.onAITap,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
      const SizedBox(width: 8),
      _buildActionButton(
        Icons.translate,
        () {
          final settings = context.read<SettingsProvider>();
          context.read<BrowserProvider>().translateCurrentTab(settings.translationLanguage);
        },
        false,
      ),
      const SizedBox(width: 8),
      // If the current tab is a translated page, provide a quick "View Original" action
      if (provider.currentTab.url != null && provider.currentTab.url!.contains('translate.google.com')) ...[
        _buildActionButton(
          Icons.language,
          () {
            try {
              final uri = Uri.parse(provider.currentTab.url!);
              final encoded = uri.queryParameters['u'] ?? '';
              if (encoded.isNotEmpty) {
                final original = Uri.decodeComponent(encoded);
                provider.navigateToUrl(original);
              }
            } catch (_) {}
          },
          false,
        ),
        const SizedBox(width: 8),
      ],
      _buildActionButton(
        Icons.shield,
        () {
          context.read<SettingsProvider>().toggleProxy();
        },
        context.watch<SettingsProvider>().proxyEnabled,
      ),
    ];
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withAlpha((0.2 * 255).round())
            : Colors.grey.shade800.withAlpha((0.5 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: Colors.green.withAlpha((0.3 * 255).round()))
            : null,
      ),
      child: Tooltip(
        message: isActive ? 'Disable proxy' : 'Enable proxy',
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              isActive ? icon : icon,
              key: ValueKey<bool>(isActive),
            ),
          ),
          color: isActive ? Colors.green : AppConstants.primaryColor,
          iconSize: 20,
          onPressed: onPressed,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }

  Widget _buildUserMenu(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      return ElevatedButton(
        onPressed: widget.onAuthTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Sign In'),
      );
    }

    return PopupMenuButton(
      icon: const Icon(Icons.person, color: AppConstants.primaryColor),
      itemBuilder: (context) => [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              widget.onSettingsTap();
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out'),
            onTap: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
          ),
        ),
      ],
    );
  }

  IconData _getWorkspaceIcon(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work_outline;
      case 'person':
        return Icons.person_outline;
      case 'research':
        return Icons.school_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'entertainment':
        return Icons.videogame_asset_outlined;
      case 'social':
        return Icons.people_outline;
      default:
        return Icons.folder_outlined;
    }
  }
}
