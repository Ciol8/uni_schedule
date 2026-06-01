class Note {
  final String? id;
  final String subjectId;
  final String title;
  final String? content;
  final bool isTask;
  final bool isCompleted;

  Note({
    this.id,
    required this.subjectId,
    required this.title,
    this.content,
    this.isTask = false,
    this.isCompleted = false,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      subjectId: json['subject_id'],
      title: json['title'],
      content: json['content'],
      isTask: json['is_task'] ?? false,
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'subject_id': subjectId,
      'title': title,
      if (content != null) 'content': content,
      'is_task': isTask,
      'is_completed': isCompleted,
    };
  }
}