class Note {
  final String? id;
  final String subjectId;
  final String title;
  final String? content;
  final bool isTask;
  final bool isCompleted;
  final int priority;

  Note({
    this.id,
    required this.subjectId,
    required this.title,
    this.content,
    this.isTask = false,
    this.isCompleted = false,
    this.priority = 1,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String?,
      subjectId: json['subject_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      isTask: json['is_task'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      priority: json['priority'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'subject_id': subjectId,
      'title': title,
      'content': content,
      'is_task': isTask,
      'is_completed': isCompleted,
      'priority': priority,
    };
  }
}