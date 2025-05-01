import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';



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
  String summaryText ="";//summaFry.json 출력 변수

  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    fetchResultJson();
  }

  //pdf 다운로드 함수
  void downloadPdf() async {
    final url = "https://amoeba-national-mayfly.ngrok-free.app/pdf/${Uri.encodeComponent(widget.directory)}";

    // ✅ 저장 권한 요청
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("저장 권한이 필요합니다.")),
      );
      return;
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;

      // ✅ 공용 Download 폴더로 저장
      final downloadDir = Directory("/storage/emulated/0/Download");
      if (!await downloadDir.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("다운로드 폴더를 찾을 수 없습니다.")),
        );
        return;
      }

      String sanitizedName = widget.name
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '') // 파일명에 쓸 수 없는 문자 제거
          .replaceAll(' ', '_');                  // 띄어쓰기는 _로 변경

      final file = File("${downloadDir.path}/${widget.name}_회의록.pdf");

      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF 다운로드 완료: ${file.path}")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF 다운로드 실패")),
      );
    }
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: downloadPdf,
                  icon: Icon(Icons.download),
                  label: Text("회의록 다운로드", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    textStyle: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),


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
