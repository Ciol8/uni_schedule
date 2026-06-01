class Subject {
  final String? id;
  final String name;
  final String color;

  Subject({
    this.id,
    required this.name,
    this.color = '#070291',
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      color: json['color'] ?? '#070291',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
    };
  }
}