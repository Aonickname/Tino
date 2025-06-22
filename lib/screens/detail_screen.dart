import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;            // HTTP 요청
import 'dart:convert';                              // JSON 디코딩
import 'package:path_provider/path_provider.dart';  // 경로 접근
import 'dart:io';                                   // 파일 입출력
import 'package:permission_handler/permission_handler.dart'; // 권한 요청
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';



// 초 단위 시간을 "MM:SS"로
String formatTime(dynamic seconds) {
  final int min = (seconds ~/ 60).toInt();
  final int sec = (seconds % 60).toInt();
  return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
}

// 말풍선 꼬리 그려주는 CustomPainter
class _BubbleArrowPainter extends CustomPainter {
  final Color color;
  _BubbleArrowPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  Map<String, double> ratios = {};
  Map<String, double> targetRatios = {};
  Timer? animationTimer;

  final List<Color> modernPalette = [
    Color(0xFF72B5E7), // Sky Blue
    Color(0xFFB4A7E7), // Soft Lavender
    Color(0xFFA1E3D8), // Mint Blue
    Color(0xFFFFC9A9), // Light Peach
  ];


  List<Map<String, dynamic>> segments = [];
  String summaryText = "";
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    fetchResultJson();
  }

  @override
  void dispose() {
    animationTimer?.cancel();
    super.dispose();
  }


  Future<Map<String, double>> fetchSpeakerRatios(String directory) async {
    final response = await http.get(
        Uri.parse('http://34.47.125.249:8000/ratio/${Uri.encodeComponent(directory)}'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      final raw = data.map((key, value) => MapEntry(key, (value as num).toDouble()));
      final total = raw.values.fold(0.0, (sum, val) => sum + val);

      // 💡 여기서 비율로 정규화
      final normalized = raw.map((key, value) => MapEntry(key, value / total));
      return normalized;
    } else {
      throw Exception('비율 불러오기 실패: ${response.body}');
    }
  }



  // PDF 다운로드
  void downloadPdf() async {
    final url =
        "http://34.47.125.249:8000/pdf/${Uri.encodeComponent(widget.directory)}";

    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("저장 권한이 필요합니다.")));
      return;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final downloadDir = Directory("/storage/emulated/0/Download");
      if (!await downloadDir.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("다운로드 폴더를 찾을 수 없습니다.")));
        return;
      }
      String sanitizedName = widget.name
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
          .replaceAll(' ', '_');
      final file = File(
          "${downloadDir.path}/${sanitizedName}_회의록.pdf");
      await file.writeAsBytes(bytes);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF 다운로드 완료: ${file.path}")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("PDF 다운로드 실패")));
    }
  }

  // STT 원문 불러오기
  void fetchResultJson() async {
    final response = await http.get(Uri.parse(
        "http://34.47.125.249:8000/result/${Uri.encodeComponent(widget.directory)}"));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        segments =
        List<Map<String, dynamic>>.from(data["segments"] ?? []);
      });
    } else {
      setState(() => segments = []);
    }
  }

  // 요약 불러오기
  void fetchSummaryJson() async {
    final response = await http.get(Uri.parse(
        "http://34.47.125.249:8000/summary/${Uri.encodeComponent(widget.directory)}"));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        summaryText = data["summary"] ?? "요약 내용이 없습니다.";
      });
    } else {
      setState(() => summaryText = "요약 파일을 불러올 수 없습니다.");
    }
  }

  // 한 구간(세그먼트)을 말풍선 형태로
  Widget buildSegmentBubble(Map<String, dynamic> seg) {
    final bg = Colors.grey.shade200;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 꼬리
          CustomPaint(
            painter: _BubbleArrowPainter(bg),
            size: Size(10, 20),
          ),
          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Speaker ${seg['speaker']}",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(seg['text'] ?? ""),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        padding: const EdgeInsets.all(16),
        child: ListView(
          padding: EdgeInsets.zero, // 기본 ListView 여백 제거
          children: [
            Text("회의 제목: ${widget.name}",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("설명: ${widget.description}"),
            SizedBox(height: 8),
            Text("날짜: ${widget.date}"),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: downloadPdf,
                  icon: Icon(Icons.download),
                  label: Text("회의록 다운로드",
                      style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    textStyle: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),
            ExpansionTile(
              title: Text(
                "화자 발언 비율",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (val) async {
                setState(() => isExpanded = val);

                // 열릴 때 최초 1회만 API 호출 & 애니메이션 시작
                if (val && targetRatios.isEmpty) {
                  final data = await fetchSpeakerRatios(widget.directory);
                  setState(() {
                    targetRatios = data;
                    ratios = { for (var k in data.keys) k: 0 }; // 초기화
                  });

                  animationTimer = Timer.periodic(Duration(milliseconds: 30), (timer) {
                    bool shouldContinue = false;

                    setState(() {
                      ratios.forEach((key, value) {
                        final target = targetRatios[key]!;
                        if ((target - value).abs() > 0.001) {
                          final step = (target - value) * 0.1; // 차이의 10%씩 접근
                          ratios[key] = value + step;
                          shouldContinue = true;
                        } else {
                          ratios[key] = target; // 마지막 값 정확히 맞춤
                        }
                      });
                    });

                    if (!shouldContinue) timer.cancel();
                  });

                }
              },
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.symmetric(vertical: 8),
              children: [
                if (ratios.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text("불러오는 중..."),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 40,
                        sectionsSpace: 4,
                        sections: ratios.entries.toList().asMap().entries.map((entry) {
                          final index = entry.key;
                          final speaker = entry.value.key;
                          final value = entry.value.value;

                          final color = modernPalette[index % modernPalette.length];
                          final brightness = (color.red * 299 + color.green * 587 + color.blue * 114) / 1000;
                          final textColor = brightness < 160 ? Colors.white : Colors.black;

                          return PieChartSectionData(
                            value: value,
                            color: color,
                            title: '화자 ${speaker}\n${(value * 100).toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,  // bold → medium 정도
                              color: textColor,
                            ),

                          );


                        }).toList(),
                      ),
                    ),
                  )
              ],
            ),





            SizedBox(height: 10),
            ExpansionTile(
              title: Text("회의 요약",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (val) {
                setState(() => isExpanded = val);
                if (val && summaryText.isEmpty) fetchSummaryJson();
              },
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(summaryText.isNotEmpty
                      ? summaryText
                      : "요약을 불러오는 중입니다..."),
                )
              ],
            ),
            
            SizedBox(height: 10),
            ExpansionTile(
              title: Text("원문",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (val) =>
                  setState(() => isExpanded = val),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.symmetric(horizontal: 0),
              children: segments.isEmpty
                  ? [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text("불러올 수 없습니다."),
                ),
              ]
                  : segments
                  .map((seg) => buildSegmentBubble(seg))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
