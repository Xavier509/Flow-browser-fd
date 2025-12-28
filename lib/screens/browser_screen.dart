import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/browser_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/browser_header.dart';
import '../widgets/browser_tabs.dart';
import '../widgets/browser_webview.dart';
import '../widgets/mobile_bottom_nav.dart';
import '../widgets/bookmarks_panel.dart';
import '../widgets/settings_modal.dart';
import '../widgets/workspaces_modal.dart';
import '../widgets/ai_assistant_panel.dart';
import '../widgets/auth_modal.dart';
import '../widgets/mobile_menu.dart';
import '../widgets/history_panel.dart';
import '../widgets/notes_panel.dart';
import '../widgets/todos_panel.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showBookmarks = false;
  bool _showSettings = false;
  bool _showWorkspaces = false;
  bool _showAIPanel = false;
  bool _showAuth = false;
  bool _showHistory = false;
  bool _showNotes = false;
  bool _showTodos = false;
  WebViewController? _webViewController;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 && 
                     MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppConstants.backgroundColor,
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Tabs bar (desktop/tablet only)
              (!isMobile) ? BrowserTabs(webViewController: _webViewController) : const SizedBox(),

              // Header with URL bar and controls
              BrowserHeader(
                onMenuTap: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                onBookmarkTap: () => setState(() => _showBookmarks = !_showBookmarks),
                onAITap: () => setState(() => _showAIPanel = !_showAIPanel),
                onWorkspaceTap: () => setState(() => _showWorkspaces = true),
                onSettingsTap: () => setState(() => _showSettings = true),
                onAuthTap: () => setState(() => _showAuth = true),
                onHistoryTap: () => setState(() {
                  final open = !_showHistory;
                  _showHistory = open;
                  if (open) {
                    _showNotes = false;
                    _showTodos = false;
                    _showBookmarks = false;
                    _showAIPanel = false;
                  }
                }),
                onNotesTap: () => setState(() {
                  final open = !_showNotes;
                  _showNotes = open;
                  if (open) {
                    _showHistory = false;
                    _showTodos = false;
                    _showBookmarks = false;
                    _showAIPanel = false;
                  }
                }),
                onTodosTap: () => setState(() {
                  final open = !_showTodos;
                  _showTodos = open;
                  if (open) {
                    _showHistory = false;
                    _showNotes = false;
                    _showBookmarks = false;
                    _showAIPanel = false;
                  }
                }),
                isMobile: isMobile,
                webViewController: _webViewController,
              ),

              // Email verification banner
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.isAuthenticated && !auth.isEmailVerified) {
                    return Container(
                      color: Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please verify your email to access all features.',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await auth.resendVerificationEmail();
                              if (!mounted) return;
                              messenger.showSnackBar(const SnackBar(content: Text('Verification email sent')));
                            },
                            child: const Text('Resend', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // (Removed duplicate tabs bar)
              
              // Main content area with webview
              Expanded(
                child: Row(
                  children: [
                    // Main browser view
                    Expanded(
                      child: Stack(
                        children: [
                          BrowserWebView(
                            onWebViewCreated: (controller) {
                              _webViewController = controller;
                            },
                          ),
                          if (!isMobile && (_showHistory || _showNotes || _showTodos || _showAIPanel || _showBookmarks))
                            Positioned.fill(
                              child: AnimatedOpacity(
                                opacity: 0.24,
                                duration: const Duration(milliseconds: 220),
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _showHistory = false;
                                    _showNotes = false;
                                    _showTodos = false;
                                    _showBookmarks = false;
                                    _showAIPanel = false;
                                  }),
                                  child: Container(color: Colors.black26),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // AI Assistant panel (desktop/tablet)
                    if (_showAIPanel && !isMobile)
                      SizedBox(
                        width: isTablet ? 320 : 380,
                        child: AIAssistantPanel(
                          webViewController: _webViewController,
                          onClose: () => setState(() => _showAIPanel = false),
                        ),
                      ),
                    
                    // Bookmarks panel (desktop/tablet)
                    if (_showBookmarks && !isMobile)
                      SizedBox(
                        width: 320,
                        child: BookmarksPanel(
                          onClose: () => setState(() => _showBookmarks = false),
                        ),
                      ),

                    // History / Notes / Todos side panels (desktop/tablet)
                    if (!isMobile) ...[
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _showHistory
                            ? SizedBox(
                                width: 360,
                                child: Material(
                                  elevation: 6,
                                  child: HistoryPanel(onClose: () => setState(() => _showHistory = false)),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _showNotes
                            ? SizedBox(
                                width: 360,
                                child: Material(
                                  elevation: 6,
                                  child: NotesPanel(onClose: () => setState(() => _showNotes = false)),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _showTodos
                            ? SizedBox(
                                width: 360,
                                child: Material(
                                  elevation: 6,
                                  child: TodosPanel(onClose: () => setState(() => _showTodos = false)),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Mobile bottom navigation
              (isMobile) ? const MobileBottomNav() : const SizedBox(),
            ],
          ),
        ),
      ),
      
      // Modals
      bottomSheet: _buildBottomSheets(context, isMobile),
    );
  }

  Widget? _buildBottomSheets(BuildContext context, bool isMobile) {
    if (isMobile && _showAIPanel) {
      return AIAssistantPanel(
        webViewController: _webViewController,
        onClose: () => setState(() => _showAIPanel = false),
        isMobile: true,
      );
    }

    // Mobile bottom sheets for History / Notes / Todos
    if (isMobile && _showHistory) {
      return HistoryPanel(onClose: () => setState(() => _showHistory = false));
    }

    if (isMobile && _showNotes) {
      return NotesPanel(onClose: () => setState(() => _showNotes = false));
    }

    if (isMobile && _showTodos) {
      return TodosPanel(onClose: () => setState(() => _showTodos = false));
    }
    
    if (isMobile && _showBookmarks) {
      return BookmarksPanel(
        onClose: () => setState(() => _showBookmarks = false),
        isMobile: true,
      );
    }
    
    if (_showSettings) {
      return SettingsModal(
        onClose: () => setState(() => _showSettings = false),
        isMobile: isMobile,
      );
    }
    
    if (_showWorkspaces) {
      return WorkspacesModal(
        onClose: () => setState(() => _showWorkspaces = false),
        isMobile: isMobile,
      );
    }
    
    if (_showAuth) {
      return AuthModal(
        onClose: () => setState(() => _showAuth = false),
      );
    }
    
    return null;
  }

  Widget _buildMobileDrawer() {
    return MobileMenu(
      onBookmarksTap: () {
        Navigator.pop(context);
        setState(() => _showBookmarks = true);
      },
      onAITap: () {
        Navigator.pop(context);
        setState(() => _showAIPanel = true);
      },
      onSettingsTap: () {
        Navigator.pop(context);
        setState(() => _showSettings = true);
      },
      onWorkspacesTap: () {
        Navigator.pop(context);
        setState(() => _showWorkspaces = true);
      },
    );
  }
}
