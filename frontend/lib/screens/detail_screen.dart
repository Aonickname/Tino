import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:unorm_dart/unorm_dart.dart' as unorm;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_info_plus/device_info_plus.dart';

// 초 단위 시간을 "MM:SS"로
String formatTime(dynamic seconds) {
  final validSeconds = (seconds is num) ? seconds.toInt() : 0;
  final min = (validSeconds ~/ 60).toInt();
  final sec = (validSeconds % 60).toInt();
  return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
}

// 말풍선 꼬리
class _BubbleArrowPainter extends CustomPainter {
  final Color color;
  _BubbleArrowPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height/2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class DetailScreen extends StatefulWidget {
  final String name, description, date, directory;
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
  // PieChart
  Map<String,double> ratios = {}, targetRatios = {};
  Timer? animationTimer;
  final List<Color> colors = [
    Color(0xFF72B5E7), Color(0xFFB4A7E7),
    Color(0xFFA1E3D8), Color(0xFFFFC9A9),
  ];

  // 원문 + 검색
  List<Map<String,dynamic>> segments = [];
  List<GlobalKey> segKeys = [];
  List<int> matchIdx = [];
  int currentMatch = 0;

  // UI 상태
  bool isExpanded = false;          // 화자/요약 탭
  bool isOriginalExpanded = false;  // 원문 탭
  String summaryText = '';
  String searchQuery = '';
  final ScrollController originalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchResultJson();
  }
  @override
  void dispose() {
    animationTimer?.cancel();
    originalScrollController.dispose();
    super.dispose();
  }

  Future<Map<String, double>> fetchSpeakerRatios(String dir) async {
    try {
      final normalizedDir = unorm.nfc(dir);
      final encodedDir = Uri.encodeFull(normalizedDir);
      final baseUrl = dotenv.env['API_BASE_URL'];
      final url = '$baseUrl/api/ratio/$encodedDir';
      print('Requesting URL: $url');

      final resp = await http.get(Uri.parse(url));

      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}: ${resp.reasonPhrase}');
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final raw = data.map((k, v) => MapEntry(k, (v as num).toDouble()));
      final total = raw.values.fold(0.0, (a, b) => a + b);
      return raw.map((k, v) => MapEntry(k, v / total));
    } catch (e) {
      print('Error fetching speaker ratios: $e');
      rethrow;
    }
  }

  Future<void> downloadPdf() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final int androidVersion = int.tryParse(androidInfo.version.release) ?? 0;

      if (androidVersion > 12) {
        var photoStatus = await Permission.photos.request();
        var videoStatus = await Permission.videos.request();
        if (!photoStatus.isGranted || !videoStatus.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF 다운로드를 위해 저장 권한이 필요합니다.')),
          );
          return;
        }
      } else {
        var storageStatus = await Permission.storage.request();
        if (storageStatus.isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF 다운로드를 위해 저장 권한이 필요합니다.')),
          );
          return;
        }
      }
    }

    final baseUrl = dotenv.env['API_BASE_URL'];
    final resp = await http.get(Uri.parse(
        '$baseUrl/api/pdf/${Uri.encodeComponent(widget.directory)}'
    ));
    if (resp.statusCode == 200) {
      final name = widget.name
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
          .replaceAll(' ','_');

      final downloadsDir = await getDownloadsDirectory();
      final downloadsPath = downloadsDir?.path;

      if (downloadsPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 폴더를 찾을 수 없습니다. 앱 전용 폴더에 저장합니다.')),
        );
        final appDir = await getApplicationDocumentsDirectory();
        final appDownloadsPath = '${appDir.path}/Download';
        final appFile = File('$appDownloadsPath/${name}_회의록.pdf');
        await appFile.create(recursive: true);
        await appFile.writeAsBytes(resp.bodyBytes);
      } else {
        final file = File('$downloadsPath/${name}_회의록.pdf');
        if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
        }
        await file.writeAsBytes(resp.bodyBytes);
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('PDF 다운로드 완료')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('PDF 다운로드 실패')));
    }
  }


  Future<void> fetchResultJson() async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    final resp = await http.get(Uri.parse(
        '$baseUrl/api/result/${Uri.encodeComponent(widget.directory)}'
    ));
    if (resp.statusCode==200) {
      final data = json.decode(utf8.decode(resp.bodyBytes));

      List<Map<String, dynamic>> processedSegments = [];
      final rawSegments = List<Map<String,dynamic>>.from(data['segments']??[]);

      if (rawSegments.isNotEmpty && rawSegments[0].containsKey('start')) {
        processedSegments = rawSegments;
      } else {
        for (var seg in rawSegments) {
          processedSegments.add({
            'text': seg['text'],
            'start': null,
            'end': null,
            'speaker': null,
          });
        }
      }

      setState(() {
        segments = processedSegments;
        segKeys = List.generate(processedSegments.length, (_) => GlobalKey());
      });
    }
  }

  Future<void> fetchSummaryJson() async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    final resp = await http.get(Uri.parse(
        '$baseUrl/api/summary/${Uri.encodeComponent(widget.directory)}'
    ));
    if (resp.statusCode==200) {
      final data = json.decode(utf8.decode(resp.bodyBytes));
      setState(() => summaryText = data['summary'] ?? '');
    }
  }

  void _showSearchDialog() {
    String input = '';
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('검색어 입력'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: '검색어를 입력해주세요'),
            onChanged: (v) => input = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('취소',
                style: TextStyle(color: Colors.black),),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  searchQuery = input;
                  matchIdx = [];
                  for (int i = 0; i < segments.length; i++) {
                    if ((segments[i]['text'] as String).contains(searchQuery)) {
                      matchIdx.add(i);
                    }
                  }
                  currentMatch = 0;
                });

                if (matchIdx.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        title: Text('검색 결과 없음'),
                        content: Text('“$searchQuery”에 대한 결과가 없습니다.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text('확인',
                              style: TextStyle(color: Colors.black),),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final ctx = segKeys[matchIdx[currentMatch]].currentContext;
                  if (ctx != null) {
                    Scrollable.ensureVisible(
                      ctx,
                      duration: Duration(milliseconds: 300),
                      alignment: 0.1,
                    );
                  } else {
                    final offset = matchIdx[currentMatch] * 80.0;
                    originalScrollController.animateTo(
                      offset,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              },
              child: Text('검색',
                style: TextStyle(color: Colors.black),),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHighlightedText(String txt) {
    if (searchQuery.isEmpty) return Text(txt);
    final parts = txt.split(searchQuery);
    final spans = <TextSpan>[];
    for (var i=0;i<parts.length;i++){
      spans.add(TextSpan(text: parts[i], style: TextStyle(color:Colors.black)));
      if (i<parts.length-1){
        spans.add(TextSpan(
          text: searchQuery,
          style: TextStyle(
            backgroundColor: Colors.yellow[300],
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ));
      }
    }
    return RichText(text: TextSpan(children:spans));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('회의 상세 보기'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding:EdgeInsets.all(16),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 상단 정보
            Text('회의 제목: ${widget.name}', style: TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
            SizedBox(height:8),
            Text('설명: ${widget.description}'),
            SizedBox(height:8),
            Text('날짜: ${widget.date}'),
            SizedBox(height:16),

            ElevatedButton.icon(
              icon: Icon(Icons.download),
              label: Text('회의록 다운로드',style:TextStyle(fontSize:12)),
              onPressed: downloadPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor:Colors.grey[200],
                foregroundColor:Colors.black,
                padding:EdgeInsets.symmetric(horizontal:10,vertical:5),
              ),
            ),

            SizedBox(height: 20),
            ExpansionTile(
              title: Text('화자 발언 비율',style:TextStyle(fontSize:18,fontWeight:FontWeight.w600)),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (v) async {
                setState(()=>isExpanded=v);
                if (v && targetRatios.isEmpty){
                  final data = await fetchSpeakerRatios(widget.directory);
                  setState(() {
                    targetRatios = data;
                    ratios = {for(var k in data.keys) k:0};
                  });
                  animationTimer = Timer.periodic(Duration(milliseconds:30),(t){
                    bool cont=false;
                    setState(() {
                      ratios.forEach((k,val){
                        final tVal = targetRatios[k]!;
                        if ((tVal-val).abs()>0.001){
                          ratios[k]= val + (tVal-val)*0.1;
                          cont=true;
                        } else {
                          ratios[k]=tVal;
                        }
                      });
                    });
                    if(!cont) t.cancel();
                  });
                }
              },
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.symmetric(vertical:8),
              children:[
                if(ratios.isEmpty)
                  Padding(padding:EdgeInsets.all(12),child:Text('불러오는 중...'))
                else
                  SizedBox(
                    height:220,
                    child: PieChart(PieChartData(
                      centerSpaceRadius:40, sectionsSpace:4,
                      sections: ratios.entries.toList().asMap().entries.map((e){
                        final idx=e.key;
                        final spk=e.value.key;
                        final val=e.value.value;
                        final c=colors[idx%colors.length];
                        final bright=(c.red*299 + c.green*587 + c.blue*114)/1000;
                        final txtC= bright<160?Colors.white:Colors.black;
                        return PieChartSectionData(
                          value: val,
                          color: c,
                          title:'화자 $spk\n${(val*100).toStringAsFixed(1)}%',
                          radius:60,
                          titleStyle:TextStyle(fontSize:12,fontWeight:FontWeight.w500,color:txtC),
                        );
                      }).toList(),
                    )),
                  ),
              ],
            ),

            SizedBox(height:10),
            ExpansionTile(
              title: Text('회의 요약',style:TextStyle(fontSize:18,fontWeight:FontWeight.w600)),
              initiallyExpanded: isExpanded,
              onExpansionChanged:(v){
                setState(()=>isExpanded=v);
                if(v && summaryText.isEmpty) fetchSummaryJson();
              },
              tilePadding:EdgeInsets.zero,
              childrenPadding:EdgeInsets.symmetric(vertical:8),
              children:[
                Padding(
                  padding:EdgeInsets.all(12.0),
                  child:Text(summaryText.isNotEmpty?summaryText:'요약을 불러오는 중입니다...'),
                )
              ],
            ),

            SizedBox(height:10),
            ExpansionTile(
              title: Text('원문',style:TextStyle(fontSize:18,fontWeight:FontWeight.w600)),
              initiallyExpanded: isOriginalExpanded,
              onExpansionChanged:(v) => setState(()=>isOriginalExpanded=v),
              tilePadding:EdgeInsets.zero,
              childrenPadding:EdgeInsets.symmetric(vertical:8),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOriginalExpanded && matchIdx.isNotEmpty) ...[
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_up),
                      color: Colors.black,
                      onPressed: () {
                        setState(() {
                          if (currentMatch > 0) {
                            currentMatch--;
                          } else {
                            currentMatch = matchIdx.length - 1;
                          }
                        });
                        final ctx = segKeys[matchIdx[currentMatch]].currentContext;
                        if (ctx != null) {
                          Scrollable.ensureVisible(
                            ctx,
                            duration: Duration(milliseconds: 300),
                            alignment: 0.1,
                          );
                        } else {
                          final offset = matchIdx[currentMatch] * 80.0;
                          originalScrollController.animateTo(
                            offset,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),

                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down),
                      color: Colors.black,
                      onPressed: () {
                        setState(() {
                          if (currentMatch < matchIdx.length - 1) {
                            currentMatch++;
                          } else {
                            currentMatch = 0;
                          }
                        });
                        final ctx = segKeys[matchIdx[currentMatch]].currentContext;
                        if (ctx != null) {
                          Scrollable.ensureVisible(
                            ctx,
                            duration: Duration(milliseconds: 300),
                            alignment: 0.1,
                          );
                        } else {
                          final offset = matchIdx[currentMatch] * 80.0;
                          originalScrollController.animateTo(
                            offset,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ],

                  if (isOriginalExpanded)
                    IconButton(
                      icon: Icon(Icons.search),
                      color: Colors.black,
                      onPressed: _showSearchDialog,
                    ),

                  if (searchQuery.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          searchQuery = '';
                          matchIdx.clear();
                          currentMatch = 0;
                        });
                        originalScrollController.jumpTo(0);
                      },
                      child: Text('되돌리기',
                        style: TextStyle(color: Colors.black),),
                    ),

                  Icon(isOriginalExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),

              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ListView.builder(
                    controller: originalScrollController,
                    itemCount: segments.length,
                    itemBuilder: (_, i) {
                      final seg = segments[i];
                      final timeLabel = seg['start'] != null ? formatTime(seg['start'] / 1000) : '시간 정보 없음';
                      final speakerLabel = seg['speaker'] != null ? 'Speaker ${seg['speaker']}' : 'Speaker 정보 없음';

                      return Container(
                        key: segKeys[i],
                        margin:EdgeInsets.only(bottom:12),
                        child:Row(
                          crossAxisAlignment:CrossAxisAlignment.start,
                          children:[
                            CustomPaint(
                              painter:_BubbleArrowPainter(Colors.grey.shade200),
                              size:Size(10,20),
                            ),
                            SizedBox(width:4),
                            Expanded(
                              child:Column(
                                crossAxisAlignment:CrossAxisAlignment.start,
                                children:[
                                  Text.rich(
                                    TextSpan(
                                      style:TextStyle(fontSize:14,fontWeight:FontWeight.bold,color:Colors.black),
                                      children:[
                                        TextSpan(text:'$speakerLabel · '),
                                        TextSpan(text:'<$timeLabel>',style:TextStyle(color:Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height:4),
                                  Container(
                                    padding:EdgeInsets.all(12),
                                    decoration:BoxDecoration(
                                      color:Colors.grey.shade200,
                                      borderRadius:BorderRadius.circular(10),
                                    ),
                                    child: _buildHighlightedText(seg['text'] ?? ''),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
