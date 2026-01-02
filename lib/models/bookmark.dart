class Bookmark {
  String id;
  String url;
  String title;
  String? favicon;
  String workspace;
  DateTime createdAt;
  bool pinned;

  Bookmark({
    required this.id,
    required this.url,
    required this.title,
    this.favicon,
    required this.workspace,
    DateTime? createdAt,
    this.pinned = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'favicon': favicon,
      'workspace': workspace,
      'createdAt': createdAt.toIso8601String(),
      'pinned': pinned,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      url: json['url'],
      title: json['title'],
      favicon: json['favicon'],
      workspace: json['workspace'],
      createdAt: DateTime.parse(json['createdAt']),
      pinned: json['pinned'] == true || json['pinned'] == 't' || json['pinned'] == 1,
    );
  }
}