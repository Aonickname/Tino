import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Map<String, String>>> _meetingEvents = {};

  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _loadMeetings() async {
    final response = await http.get(
      Uri.parse("http://34.47.125.249:8000/meetings"),
      headers: {'ngrok-skip-browser-warning': 'true'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Map<DateTime, List<Map<String, String>>> meetings = {};

      data.forEach((dateStr, meetingList) {
        DateTime date = DateTime.parse(dateStr);
        List<Map<String, String>> list = [];

        for (var item in meetingList) {
          list.add({
            "name": item["name"] ?? "",
            "description": item["description"] ?? "",
            "directory": item["directory"] ?? "",
          });
        }

        meetings[date] = list;
      });

      setState(() {
        _meetingEvents = meetings;
      });

      print("📅 일정 데이터 불러옴: $_meetingEvents");
    } else {
      print("서버 오류: ${response.statusCode}");
    }
  }

  void _goToToday() {
    setState(() {
      _selectedDay = DateTime.now();
      _focusedDay = DateTime.now();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "지난 회의록 보기",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        actions: [
          OutlinedButton(
            onPressed: _goToToday,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.black, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text("오늘", style: TextStyle(fontSize: 16, color: Colors.black)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                markerDecoration: BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
              ),
              headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true),
              daysOfWeekStyle: DaysOfWeekStyle(weekendStyle: TextStyle(color: Colors.red)),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  DateTime normalizedDate = normalizeDate(date);
                  if (_meetingEvents.containsKey(normalizedDate)) {
                    return Positioned(
                      bottom: 5,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            SizedBox(height: 20),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_selectedDay.year}년 ${_selectedDay.month}월 ${_selectedDay.day}일 회의 내역",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _meetingEvents.containsKey(normalizeDate(_selectedDay))
                      ? Column(
                    children: _meetingEvents[normalizeDate(_selectedDay)]!
                        .map((event) => ListTile(
                      leading: Icon(Icons.event_note, color: Colors.blue),
                      title: Text(event["name"] ?? ""),
                      subtitle: Text(event["description"] ?? ""),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(
                              name: event["name"] ?? "",
                              description: event["description"]?.isNotEmpty == true
                                  ? event["description"]!
                                  : "설명이 없습니다.",
                              date:
                              "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}",
                              directory: event["directory"] ?? "",
                            ),
                          ),
                        );
                      },
                    ))
                        .toList(),
                  )
                      : Text("회의 일정이 없습니다.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
