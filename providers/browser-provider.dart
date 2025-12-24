import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/workspace.dart';
import '../models/tab_model.dart';
import '../models/bookmark.dart';

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
  }
  
  // Getters
  List<Workspace> get workspaces => _workspaces;
  int get activeWorkspaceIndex => _activeWorkspaceIndex;
  int get activeTabIndex => _activeTabIndex;
  List<Bookmark> get bookmarks => _bookmarks;
  String get urlInput => _urlInput;
  
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
  }
  
  void closeTab(int index) {
    if (currentWorkspace.tabs.length <= 1) return;
    currentWorkspace.tabs.removeAt(index);
    if (_activeTabIndex >= index && _activeTabIndex > 0) {
      _activeTabIndex--;
    }
    _saveWorkspaces();
    notifyListeners();
  }
  
  void switchTab(int index) {
    _activeTabIndex = index;
    _urlInput = currentTab.url;
    notifyListeners();
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
  }
  
  void setUrlInput(String url) {
    _urlInput = url;
    notifyListeners();
  }
  
  // Navigation
  void navigateToUrl(String url) {
    String finalUrl = url.trim();
    
    if (finalUrl.isEmpty) return;
    
    // Check if it's a search query or URL
    final isUrl = RegExp(r'^(https?:\/\/)|(www\.)|(\w+\.\w+)').hasMatch(finalUrl);
    
    if (!isUrl) {
      // It's a search query - use Google
      finalUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(finalUrl)}';
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
  
  void goHome() {
    navigateToUrl('about:blank');
  }
  
  // Bookmarks
  void addBookmark() {
    if (currentTab.url == 'about:blank') return;
    
    final bookmark = Bookmark(
      id: _uuid.v4(),
      url: currentTab.url,
      title: currentTab.title,
      workspace: currentWorkspace.name,
    );
    
    _bookmarks.add(bookmark);
    _saveBookmarks();
    notifyListeners();
  }
  
  void removeBookmark(String id) {
    _bookmarks.removeWhere((b) => b.id == id);
    _saveBookmarks();
    notifyListeners();
  }
  
  bool isBookmarked(String url) {
    return _bookmarks.any((b) => b.url == url);
  }
}
