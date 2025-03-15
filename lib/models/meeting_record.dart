import 'dart:io';

class MeetingRecord {
  final int? id;
  final String title;
  final String attendees;
  final String meetingTime;
  final String duration;
  final String meetingEndTime;
  final String recorder;
  final String reviewer;
  final String audioPath;
  final String content;
  final DateTime createdAt;
  final String transcription;

  MeetingRecord({
    this.id,
    required this.title,
    required this.attendees,
    required this.meetingTime,
    required this.duration,
    required this.meetingEndTime,
    required this.recorder,
    required this.reviewer,
    required this.audioPath,
    required this.content,
    DateTime? createdAt,
    this.transcription = '',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'attendees': attendees,
      'meetingTime': meetingTime,
      'duration': duration,
      'meetingEndTime': meetingEndTime,
      'recorder': recorder,
      'reviewer': reviewer,
      'audioPath': audioPath,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'transcription': transcription,
    };
  }

  factory MeetingRecord.fromMap(Map<String, dynamic> map) {
    return MeetingRecord(
      id: map['id'] as int,
      title: map['title'] as String,
      attendees: map['attendees'] as String,
      meetingTime: map['meetingTime'] as String,
      duration: map['duration'] as String,
      meetingEndTime: map['meetingEndTime'] as String,
      recorder: map['recorder'] as String,
      reviewer: map['reviewer'] as String,
      audioPath: map['audioPath'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      transcription: map['transcription'] as String? ?? '',
    );
  }
}
