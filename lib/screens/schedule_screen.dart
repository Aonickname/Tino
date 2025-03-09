import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // 날짜를 표준화하는 함수 (시간 정보 제거)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // 예제 회의 일정
  final Map<DateTime, List<String>> _meetingEvents = {
    normalizeDate(DateTime(2025, 2, 17)): ["팀 미팅", "기획 회의"],
    normalizeDate(DateTime(2025, 2, 19)): ["공부하기 싫은 날", "클라이언트 미팅"],
    normalizeDate(DateTime(2025, 2, 20)): ["프로젝트 리뷰"],
    normalizeDate(DateTime(2025, 3, 4)): ["개강"],
    normalizeDate(DateTime(2025, 3, 6)): ["데모 발표 전 회의"],
  };

  // "오늘" 버튼 클릭 시 현재 날짜로 이동하는 함수
  void _goToToday() {
    setState(() {
      _selectedDay = DateTime.now();
      _focusedDay = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "지난 회의록 보기",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: _goToToday,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.black, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              "오늘",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
      body: Column(
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
              todayDecoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.pink,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.red),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                DateTime normalizedDate = normalizeDate(date);

                if (_meetingEvents.containsKey(normalizedDate)) {
                  return Positioned(
                    bottom: 5,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                      ),
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
                    title: Text(event, style: TextStyle(fontSize: 16)),
                  ))
                      .toList(),
                )
                    : Text(
                  "회의 일정이 없습니다.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
