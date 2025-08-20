import 'dart:convert';

class MeetingModel {
  final DateTime date;
  final List<String> events;

  MeetingModel({required this.date, required this.events});

  factory MeetingModel.fromJson(String date, List<dynamic> events) {
    return MeetingModel(
      date: DateTime.parse(date),
      events: events.cast<String>(),
    );
  }
}
