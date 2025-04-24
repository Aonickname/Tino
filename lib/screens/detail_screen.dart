import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

String formatTime(dynamic seconds) {
  final int min = (seconds ~/ 60).toInt();
  final int sec = (seconds % 60).toInt();
  return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
}

class DetailScreen extends StatefulWidget {
  final String name;
  final String description;
  final String date;
  final String directory;

  DetailScreen({
    required this.name,
    required this.description,
    required this.date,
    required this.directory,
  });

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  List<Map<String, dynamic>> segments = [];//result.json 출력 변수
  String summaryText ="";//summary.json 출력 변수

  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    fetchResultJson();
  }

  //result 읽어오기
  void fetchResultJson() async {
    final response = await http.get(
      Uri.parse("https://amoeba-national-mayfly.ngrok-free.app/result/${Uri.encodeComponent(widget.directory)}"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        segments = List<Map<String, dynamic>>.from(data["segments"]);
      });
    } else {
      setState(() {
        segments = [];
      });
    }
  }
  
  //summary 읽어오기
  void fetchSummaryJson() async {
    final response = await http.get(
      Uri.parse("https://amoeba-national-mayfly.ngrok-free.app/summary/${Uri.encodeComponent(widget.directory)}"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        summaryText = data["summary"] ?? "요약 내용이 없습니다.";
      });
    } else {
      setState(() {
        summaryText = "요약 파일을 불러올 수 없습니다.";
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("회의 상세 보기"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("회의 제목: ${widget.name}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("설명: ${widget.description}"),
            SizedBox(height: 8),
            Text("날짜: ${widget.date}"),
            SizedBox(height: 16),

            ExpansionTile(
              title: Text("회의 요약", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (val) {
                setState(() => isExpanded = val);
                if (val && summaryText.isEmpty) fetchSummaryJson();
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(summaryText.isNotEmpty ? summaryText : "요약을 불러오는 중입니다..."),
                )
              ],
            ),




            SizedBox(height: 16),
            ExpansionTile(
              title: Text("원문", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (val) => setState(() => isExpanded = val),
              children: segments.isEmpty
                  ? [Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("불러올 수 없습니다."),
              )]
                  : segments.map((seg) {
                final start = formatTime(seg["start"]);
                final end = formatTime(seg["end"]);
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("[$start ~ $end]", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(seg["text"]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
