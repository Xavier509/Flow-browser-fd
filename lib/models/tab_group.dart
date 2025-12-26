class TabGroup {
  String id;
  String name;
  int color;
  List<String> tabIds; // IDs of tabs in this group
  bool isCollapsed; // Whether the group is collapsed/minimized

  TabGroup({
    required this.id,
    required this.name,
    required this.color,
    this.tabIds = const [],
    this.isCollapsed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'tabIds': tabIds,
      'isCollapsed': isCollapsed,
    };
  }

  factory TabGroup.fromJson(Map<String, dynamic> json) {
    return TabGroup(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      tabIds: List<String>.from(json['tabIds'] ?? []),
      isCollapsed: json['isCollapsed'] ?? false,
    );
  }
}