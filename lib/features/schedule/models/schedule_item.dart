import 'subject.dart';

class ScheduleItem {
  final String? id;
  final String subjectId;
  final String classType;
  final String? location;
  final String? meetingLink;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isRecurring;
  final int reminderOffset;
  final Subject? subject; // Automatyczne dołączanie danych z innej tabeli (JOIN)

  ScheduleItem({
    this.id,
    required this.subjectId,
    required this.classType,
    this.location,
    this.meetingLink,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isRecurring = true,
    this.reminderOffset = 15,
    this.subject,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'],
      subjectId: json['subject_id'],
      classType: json['class_type'],
      location: json['location'],
      meetingLink: json['meeting_link'],
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      isRecurring: json['is_recurring'] ?? true,
      reminderOffset: json['reminder_offset'] ?? 15,
      // Supabase zwraca połączone dane jako zagnieżdżony obiekt
      subject: json['subjects'] != null ? Subject.fromJson(json['subjects']) : null, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'subject_id': subjectId,
      'class_type': classType,
      if (location != null) 'location': location,
      if (meetingLink != null) 'meeting_link': meetingLink,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_recurring': isRecurring,
      'reminder_offset': reminderOffset,
    };
  }
}