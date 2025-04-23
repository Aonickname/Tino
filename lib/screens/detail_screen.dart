import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String resultText = "불러오는 중...";

  @override
  void initState() {
    super.initState();
    fetchResultJson();
  }

  void fetchResultJson() async {
    final response = await http.get(
        Uri.parse("https://amoeba-national-mayfly.ngrok-free.app/result/${Uri.encodeComponent(widget.directory)}")

    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        resultText = data["text"] ?? "텍스트가 없습니다.";
      });
    } else {
      setState(() {
        resultText = "불러오기 실패: ${response.statusCode}";
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // 👈 이거 추가!
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("회의 제목: ${widget.name}", style: TextStyle(fontSize: 24)),
              SizedBox(height: 8),
              Text("설명: ${widget.description}"),
              SizedBox(height: 8),
              Text("날짜: ${widget.date}"),
              SizedBox(height: 16),
              Text("회의 음성 원문", style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text(resultText),
            ],
          ),
        ),
      ),

    );
  }
}
