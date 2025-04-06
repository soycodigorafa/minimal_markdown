import 'dart:convert';

class RecentFile {
  final String path;
  final String name;
  final DateTime lastOpened;

  RecentFile({
    required this.path,
    required this.name,
    required this.lastOpened,
  });

  RecentFile copyWith({
    String? path,
    String? name,
    DateTime? lastOpened,
  }) {
    return RecentFile(
      path: path ?? this.path,
      name: name ?? this.name,
      lastOpened: lastOpened ?? this.lastOpened,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'lastOpened': lastOpened.millisecondsSinceEpoch,
    };
  }

  factory RecentFile.fromMap(Map<String, dynamic> map) {
    return RecentFile(
      path: map['path'] ?? '',
      name: map['name'] ?? '',
      lastOpened: DateTime.fromMillisecondsSinceEpoch(map['lastOpened']),
    );
  }

  String toJson() => json.encode(toMap());

  factory RecentFile.fromJson(String source) =>
      RecentFile.fromMap(json.decode(source));

  @override
  String toString() =>
      'RecentFile(path: $path, name: $name, lastOpened: $lastOpened)';
}
