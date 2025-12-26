
import 'tab_group.dart';

class Workspace {
  final String id;
  String name;
  String icon;
  int color;
  List<TabModel> tabs;
  List<TabGroup> tabGroups;

  Workspace({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.tabs,
    this.tabGroups = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'tabs': tabs.map((t) => t.toJson()).toList(),
      'tabGroups': tabGroups.map((g) => g.toJson()).toList(),
    };
  }

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as int,
      tabs: (json['tabs'] as List)
          .map((t) => TabModel.fromJson(Map<String, dynamic>.from(t)))
          .toList(),
      tabGroups: (json['tabGroups'] as List?)
          ?.map((g) => TabGroup.fromJson(Map<String, dynamic>.from(g)))
          .toList() ?? [],
    );
  }
}

// models/tab_model.dart
class TabModel {
  final String id;
  String url;
  String title;
  List<String> history;
  int historyIndex;
  bool isLoading;
  
  TabModel({
    required this.id,
    required this.url,
    required this.title,
    List<String>? history,
    this.historyIndex = 0,
    this.isLoading = false,
  }) : history = history ?? [url];
  
  void addToHistory(String url) {
    // Remove forward history when navigating to new page
    history = history.sublist(0, historyIndex + 1);
    history.add(url);
    historyIndex = history.length - 1;
  }
  
  bool get canGoBack => historyIndex > 0;
  bool get canGoForward => historyIndex < history.length - 1;
  
  void goBack() {
    if (canGoBack) {
      historyIndex--;
      url = history[historyIndex];
    }
  }
  
  void goForward() {
    if (canGoForward) {
      historyIndex++;
      url = history[historyIndex];
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'history': history,
      'historyIndex': historyIndex,
    };
  }
  
  factory TabModel.fromJson(Map<String, dynamic> json) {
    return TabModel(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      history: (json['history'] as List).cast<String>(),
      historyIndex: json['historyIndex'] as int,
    );
  }
}
