class Person {
  final int? id;
  final String name;
  final DateTime createdAt;
  final bool isCashbook;

  Person({
    this.id,
    required this.name,
    required this.createdAt,
    this.isCashbook = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'is_cashbook': isCashbook ? 1 : 0,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      isCashbook: map['is_cashbook'] == 1,
    );
  }

  Person copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    bool? isCashbook,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isCashbook: isCashbook ?? this.isCashbook,
    );
  }
}
