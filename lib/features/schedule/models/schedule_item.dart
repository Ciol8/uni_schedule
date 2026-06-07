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
  final int reminderOffset;
  final Subject? subject;
  final String? specificDate;

  // --- NOWA ZMIENNA: Lista odwołanych dat ---
  final List<String> cancelledDates;

  ScheduleItem({
    this.id,
    required this.subjectId,
    required this.classType,
    this.location,
    this.meetingLink,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.reminderOffset = 15,
    this.subject,
    this.specificDate,
    this.cancelledDates = const [], // Domyślnie pusta lista
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] as String?,
      subjectId: json['subject_id'] as String,
      classType: json['class_type'] as String,
      location: json['location'] as String?,
      meetingLink: json['meeting_link'] as String?,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      reminderOffset: json['reminder_offset'] as int? ?? 15,
      specificDate: json['specific_date'] as String?,
      subject: json['subjects'] != null ? Subject.fromJson(json['subjects']) : null,
      // Magia: wyciągamy listę odwołanych dat z podrzędnej tabeli
      cancelledDates: (json['schedule_cancellations'] as List<dynamic>?)
          ?.map((e) => e['cancelled_date'] as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'subject_id': subjectId,
      'class_type': classType,
      'location': location,
      'meeting_link': meetingLink,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'reminder_offset': reminderOffset,
      'specific_date': specificDate,
    };
  }
}