import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workspace.dart';
import '../models/bookmark.dart';
import '../models/tab_group.dart';
import '../utils/constants.dart';

class BrowserProvider with ChangeNotifier {
  final Box _workspacesBox = Hive.box('workspaces');
  final Box _bookmarksBox = Hive.box('bookmarks');
  final _uuid = const Uuid();
  
  List<Workspace> _workspaces = [];
  int _activeWorkspaceIndex = 0;
  int _activeTabIndex = 0;
  List<Bookmark> _bookmarks = [];
  String _urlInput = '';
  
  BrowserProvider() {
    _loadData();
    // Attempt to sync bookmarks from Supabase on startup (non-blocking)
    Future(() => syncBookmarksFromSupabase());
    // Sync tabs and sessions too
    Future(() => syncTabsFromSupabase());
    Future(() => syncSessionsFromSupabase());
  }
  
  // Getters
  List<Workspace> get workspaces => _workspaces;
  int get activeWorkspaceIndex => _activeWorkspaceIndex;
  int get activeTabIndex => _activeTabIndex;
  List<Bookmark> get bookmarks => _bookmarks;
  String get urlInput => _urlInput;
  
  int get currentTabIndex => _activeTabIndex;
  List<TabModel> get tabs => currentWorkspace.tabs;
  Workspace get currentWorkspace => _workspaces[_activeWorkspaceIndex];
  TabModel get currentTab => currentWorkspace.tabs[_activeTabIndex];
  
  // Load data from storage
  void _loadData() {
    // Load workspaces
    final workspacesData = _workspacesBox.get('workspaces');
    if (workspacesData != null && workspacesData is List) {
      _workspaces = workspacesData
          .map((data) => Workspace.fromJson(Map<String, dynamic>.from(data)))
          .toList();
    }
    
    // Create default workspace if none exist
    if (_workspaces.isEmpty) {
      _workspaces = [
        Workspace(
          id: _uuid.v4(),
          name: 'Personal',
          icon: 'person',
          color: 0xFFa855f7,
          tabs: [
            TabModel(
              id: _uuid.v4(),
              url: 'about:blank',
              title: 'New Tab',
            ),
          ],
        ),
      ];
      _saveWorkspaces();
    }
    
    // Load bookmarks
    final bookmarksData = _bookmarksBox.get('bookmarks');
    if (bookmarksData != null && bookmarksData is List) {
      _bookmarks = bookmarksData
          .map((data) => Bookmark.fromJson(Map<String, dynamic>.from(data)))
          .toList();
    }
    
    notifyListeners();
  }
  
  void _saveWorkspaces() {
    _workspacesBox.put(
      'workspaces',
      _workspaces.map((w) => w.toJson()).toList(),
    );
  }
  
  void _saveBookmarks() {
    _bookmarksBox.put(
      'bookmarks',
      _bookmarks.map((b) => b.toJson()).toList(),
    );
  }

  // Supabase sync for bookmarks
  Future<void> syncBookmarksFromSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final List data = await Supabase.instance.client
          .from('bookmarks')
          .select()
          .eq('user_id', user.id);
      // Merge remote bookmarks into local, avoiding duplicates
      for (final item in data) {
        try {
          final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
          final remote = Bookmark(
            id: map['id'].toString(),
            url: map['url'] ?? '',
            title: map['title'] ?? map['url'] ?? '',
            favicon: map['favicon'],
            workspace: map['workspace'] ?? currentWorkspace.name,
            createdAt: map['created_at'] != null
                ? DateTime.parse(map['created_at'])
                : DateTime.now(),
          );

          if (!_bookmarks.any((b) => b.id == remote.id || b.url == remote.url)) {
            _bookmarks.add(remote);
          }
        } catch (_) {}
      }

      _saveBookmarks();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _upsertBookmarkToSupabase(Bookmark b) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final payload = {
        'id': b.id,
        'user_id': user.id,
        'url': b.url,
        'title': b.title,
        'favicon': b.favicon,
        'workspace': b.workspace,
        'created_at': b.createdAt.toIso8601String(),
      };

      await Supabase.instance.client.from('bookmarks').upsert(payload);
    } catch (_) {}
  }

  Future<void> _deleteBookmarkFromSupabase(String id) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('bookmarks')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (_) {}
  }

  // Tabs sync
  Future<void> syncTabsFromSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final List data = await Supabase.instance.client
          .from('tabs')
          .select()
          .eq('user_id', user.id);
      for (final item in data) {
        try {
          final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
          final remote = TabModel.fromJson({
            'id': map['id'].toString(),
            'url': map['url'] ?? '',
            'title': map['title'] ?? map['url'] ?? '',
            'history': map['history'] ?? [],
            'historyIndex': map['history_index'] ?? 0,
          });

          // Merge into matching workspace tabs if not present
          var exists = false;
          for (final ws in _workspaces) {
            if (ws.tabs.any((t) => t.id == remote.id || t.url == remote.url)) {
              exists = true;
              break;
            }
          }
          if (!exists) {
            // attach to first workspace
            _workspaces[0].tabs.add(remote);
          }
        } catch (_) {}
      }

      _saveWorkspaces();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _upsertTabToSupabase(TabModel t) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final payload = {
        'id': t.id,
        'user_id': user.id,
        'workspace': currentWorkspace.name,
        'tab_index': _activeTabIndex,
        'url': t.url,
        'title': t.title,
        'history': t.history,
        'is_active': t.id == currentTab.id,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('tabs').upsert(payload);
    } catch (_) {}
  }

  Future<void> _deleteTabFromSupabase(String id) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client.from('tabs').delete().eq('id', id).eq('user_id', user.id);
    } catch (_) {}
  }

  // Sessions sync (upsert entire workspaces JSON)
  Future<void> syncSessionsFromSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final List data = await Supabase.instance.client.from('sessions').select().eq('user_id', user.id);
      if (data.isEmpty) return;

      // For simplicity: merge first session's workspaces into local if local is empty or smaller
      final Map<String, dynamic> first = Map<String, dynamic>.from(data.first as Map);
      if (first['workspaces'] != null) {
        final remoteWorkspaces = List<dynamic>.from(first['workspaces']);
        if (_workspaces.isEmpty || remoteWorkspaces.length >= _workspaces.length) {
          _workspaces = remoteWorkspaces
              .map((w) => Workspace.fromJson(Map<String, dynamic>.from(w as Map)))
              .toList();
          _saveWorkspaces();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _upsertSessionToSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final payload = {
        'user_id': user.id,
        'name': 'default',
        'workspaces': _workspaces.map((w) => w.toJson()).toList(),
      };

      await Supabase.instance.client.from('sessions').upsert(payload);
    } catch (_) {}
  }
  
  // Workspace Management
  void addWorkspace(String name, String icon, int color, String description) {
    final workspace = Workspace(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      color: color,
      tabs: [
        TabModel(
          id: _uuid.v4(),
          url: 'about:blank',
          title: 'New Tab',
        ),
      ],
    );
    _workspaces.add(workspace);
    _activeWorkspaceIndex = _workspaces.length - 1;
    _activeTabIndex = 0;
    _saveWorkspaces();
    notifyListeners();
  }
  
  void deleteWorkspace(int index) {
    if (_workspaces.length <= 1) return;
    _workspaces.removeAt(index);
    if (_activeWorkspaceIndex >= index && _activeWorkspaceIndex > 0) {
      _activeWorkspaceIndex--;
    }
    _activeTabIndex = 0;
    _saveWorkspaces();
    notifyListeners();
  }
  
  void switchWorkspace(int index) {
    _activeWorkspaceIndex = index;
    _activeTabIndex = 0;
    notifyListeners();
  }
  
  void createWorkspace(String name, String icon, int color) {
    final workspace = Workspace(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      color: color,
      tabs: [
        TabModel(
          id: _uuid.v4(),
          url: 'about:blank',
          title: 'New Tab',
        ),
      ],
    );
    _workspaces.add(workspace);
    _activeWorkspaceIndex = _workspaces.length - 1;
    _activeTabIndex = 0;
    _saveWorkspaces();
    Future(() => _upsertSessionToSupabase());
    notifyListeners();
  }
  
  // Tab Management
  void addTab() {
    final newTab = TabModel(
      id: _uuid.v4(),
      url: 'about:blank',
      title: 'New Tab',
    );
    _workspaces[_activeWorkspaceIndex].tabs.add(newTab);
    _activeTabIndex = currentWorkspace.tabs.length - 1;
    _saveWorkspaces();
    notifyListeners();
    // Sync new tab to Supabase
    Future(() => _upsertTabToSupabase(newTab));
    Future(() => _upsertSessionToSupabase());
  }
  
  void closeTab(int index) {
    if (currentWorkspace.tabs.length <= 1) return;
    currentWorkspace.tabs.removeAt(index);
    if (_activeTabIndex >= index && _activeTabIndex > 0) {
      _activeTabIndex--;
    }
    _saveWorkspaces();
    notifyListeners();
    // Delete tab remotely if it existed
    try {
      final closedId = currentWorkspace.tabs[index].id;
      Future(() => _deleteTabFromSupabase(closedId));
    } catch (_) {}
    Future(() => _upsertSessionToSupabase());
  }
  
  void switchTab(int index) {
    _activeTabIndex = index;
    _urlInput = currentTab.url;
    notifyListeners();
  }

  void reorderTabs(List<TabModel> newOrder) {
    _workspaces[_activeWorkspaceIndex].tabs = newOrder;
    _saveWorkspaces();
    Future(() => _upsertSessionToSupabase());
  }

  void updateCurrentTab({String? url, String? title}) {
    if (url != null) {
      currentTab.url = url;
      currentTab.addToHistory(url);
    }
    if (title != null) {
      currentTab.title = title;
    }
    _saveWorkspaces();
    notifyListeners();
    // Sync updated tab
    Future(() => _upsertTabToSupabase(currentTab));
    Future(() => _upsertSessionToSupabase());
  }
  
  void setUrlInput(String url) {
    _urlInput = url;
    notifyListeners();
  }
  
  // Navigation
  void navigateToUrl(String url, [String? searchEngine]) {
    String finalUrl = url.trim();
    
    if (finalUrl.isEmpty) return;
    
    // Check if it's a search query or URL
    final isUrl = RegExp(r'^(https?:\/\/)|(www\.)|(\w+\.\w+)').hasMatch(finalUrl);
    
    if (!isUrl) {
      // It's a search query - use the specified search engine or default to Google
      final engine = searchEngine ?? 'Google';
      var searchUrl = AppConstants.searchEngines[engine] ?? AppConstants.searchEngines['Google']!;
      // Support both placeholder style (contains %s) and simple suffix style
      if (searchUrl.contains('%s')) {
        finalUrl = searchUrl.replaceAll('%s', Uri.encodeComponent(finalUrl));
      } else {
        // append encoded query
        finalUrl = '${searchUrl}${Uri.encodeComponent(finalUrl)}';
      }
    } else if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }
    
    updateCurrentTab(url: finalUrl);
    _urlInput = finalUrl;
  }
  
  void goBack() {
    if (currentTab.canGoBack) {
      currentTab.goBack();
      _urlInput = currentTab.url;
      notifyListeners();
    }
  }
  
  void goForward() {
    if (currentTab.canGoForward) {
      currentTab.goForward();
      _urlInput = currentTab.url;
      notifyListeners();
    }
  }
  
  void reload() {
    notifyListeners();
  }
  
  void duplicateTab(int index) {
    final originalTab = tabs[index];
    final newTab = TabModel(
      id: _uuid.v4(),
      url: originalTab.url,
      title: originalTab.title,
    );
    currentWorkspace.tabs.add(newTab);
    _activeTabIndex = currentWorkspace.tabs.length - 1;
    _saveWorkspaces();
    notifyListeners();
  }

  // Tab Groups
  void createTabGroup(String name, int color, List<int> tabIndices) {
    final group = TabGroup(
      id: _uuid.v4(),
      name: name,
      color: color,
      tabIds: tabIndices.map((i) => tabs[i].id).toList(),
    );
    currentWorkspace.tabGroups.add(group);
    _saveWorkspaces();
    notifyListeners();
  }

  void toggleTabGroup(String groupId) {
    final group = currentWorkspace.tabGroups.firstWhere((g) => g.id == groupId);
    group.isCollapsed = !group.isCollapsed;
    _saveWorkspaces();
    notifyListeners();
  }

  void removeTabFromGroup(String tabId, String groupId) {
    final group = currentWorkspace.tabGroups.firstWhere((g) => g.id == groupId);
    group.tabIds.remove(tabId);
    if (group.tabIds.isEmpty) {
      currentWorkspace.tabGroups.removeWhere((g) => g.id == groupId);
    }
    _saveWorkspaces();
    notifyListeners();
  }

  void addTabToGroup(String tabId, String groupId) {
    final group = currentWorkspace.tabGroups.firstWhere((g) => g.id == groupId);
    if (!group.tabIds.contains(tabId)) {
      group.tabIds.add(tabId);
      _saveWorkspaces();
      notifyListeners();
    }
  }

  void deleteTabGroup(String groupId) {
    final group = currentWorkspace.tabGroups.firstWhere((g) => g.id == groupId);
    currentWorkspace.tabGroups.remove(group);
    _saveWorkspaces();
    notifyListeners();
  }

  void goHome() {
    navigateToUrl('about:blank');
  }

  // Bookmarks
  void addBookmark() {
    if (currentTab.url == 'about:blank') return;

    // Check if user is authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return; // Should be checked in UI, but double-check here

    // Prevent duplicates
    if (isBookmarked(currentTab.url)) return;

    final bookmark = Bookmark(
      id: _uuid.v4(),
      url: currentTab.url,
      title: currentTab.title,
      workspace: currentWorkspace.name,
    );

    _bookmarks.add(bookmark);
    _saveBookmarks();
    notifyListeners();
    // Fire-and-forget sync to Supabase
    Future(() => _upsertBookmarkToSupabase(bookmark));
  }
  
  void removeBookmark(String id) {
    _bookmarks.removeWhere((b) => b.id == id);
    _saveBookmarks();
    notifyListeners();
    // Fire-and-forget delete on Supabase
    Future(() => _deleteBookmarkFromSupabase(id));
  }
  
  bool isBookmarked(String url) {
    return _bookmarks.any((b) => b.url == url);
  }
}
