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
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';



// 초 단위 시간을 "MM:SS"로
String formatTime(dynamic seconds) {
  final min = (seconds ~/ 60).toInt();
  final sec = (seconds % 60).toInt();
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
      // unorm.nfc()를 사용하여 dir 변수를 정규화
      final normalizedDir = unorm.nfc(dir);

      // Uri.encodeComponent 대신 Uri.encodeFull 사용
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

  // Future<void> downloadPdf() async {
  //   // iOS에서는 저장 권한이 필요 없습니다. (앱 문서 폴더 사용)
  //   // 안드로이드에서만 필요합니다.
  //   if (Platform.isAndroid) {
  //     if (!await Permission.storage.request().isGranted) {
  //       ScaffoldMessenger.of(context)
  //           .showSnackBar(SnackBar(content: Text('저장 권한이 필요합니다.')));
  //       return;
  //     }
  //   }
  //
  //   final baseUrl = dotenv.env['API_BASE_URL'];
  //   final resp = await http.get(Uri.parse(
  //       '$baseUrl/api/pdf/${Uri.encodeComponent(widget.directory)}'
  //   ));
  //
  //   if (resp.statusCode == 200) {
  //     // 파일명 정리
  //     final name = widget.name
  //         .replaceAll(RegExp(r'[\\/:*?"<>|]'),'')
  //         .replaceAll(' ','_');
  //
  //     // 플랫폼에 따라 저장 폴더 경로를 가져옵니다.
  //     // iOS의 경우 getApplicationDocumentsDirectory() 사용
  //     final dir = await getApplicationDocumentsDirectory();
  //
  //     // 파일 객체 생성 및 바이트 쓰기
  //     final file = File('${dir.path}/${name}_회의록.pdf');
  //     await file.writeAsBytes(resp.bodyBytes);
  //
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text('PDF 다운로드 완료')));
  //
  //   } else {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text('PDF 다운로드 실패')));
  //   }
  // }


// //  회의록 다운로드 버튼
//   Future<void> downloadPdf() async {
//     final baseUrl = dotenv.env['API_BASE_URL'];
//     final resp = await http.get(Uri.parse(
//         '$baseUrl/api/pdf/${Uri.encodeComponent(widget.directory)}'
//     ));
//
//     if (resp.statusCode == 200) {
//       // 파일명 정리
//       final name = widget.name
//           .replaceAll(RegExp(r'[\\/:*?"<>|]'),'')
//           .replaceAll(' ','_');
//
//       // 플랫폼에 따라 저장 폴더 경로를 가져옵니다.
//       // iOS의 경우 getApplicationDocumentsDirectory() 사용
//       final dir = await getApplicationDocumentsDirectory();
//
//       //앱 내에서 숨겨진 저장소 보기(TEST)
//       // final files = dir.listSync();
//       // 파일 객체 생성 및 바이트 쓰기
//       final file = File('${dir.path}/${name}_회의록.pdf');
//       await file.writeAsBytes(resp.bodyBytes);
//
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('PDF 다운로드 완료')));
//
//     } else {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('PDF 다운로드 실패')));
//     }
//   }

  Future<void> downloadPdf() async {
    if (Platform.isAndroid) {
      // 안드로이드 버전별 권한 요청
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final int androidVersion = int.tryParse(androidInfo.version.release) ?? 0;

      if (androidVersion > 12) {
        // 안드로이드 13 (API 33) 이상
        var photoStatus = await Permission.photos.request();
        var videoStatus = await Permission.videos.request();
        if (!photoStatus.isGranted || !videoStatus.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF 다운로드를 위해 저장 권한이 필요합니다.')),
          );
          return;
        }
      } else {
        // 안드로이드 12 (API 32) 이하
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

    //   if (resp.statusCode == 200) {
    //     final name = widget.name
    //         .replaceAll(RegExp(r'[\\/:*?"<>|]'),'')
    //         .replaceAll(' ','_');
    //
    //     // 👇 이 부분이 중요해요! 공용 저장소 경로를 가져옵니다.
    //     final directory = await getExternalStorageDirectory();
    //     final downloadsPath = '${directory?.path}/Download';
    //
    //     // 폴더가 없다면 새로 만듭니다.
    //     final saveDir = Directory(downloadsPath);
    //     if (!await saveDir.exists()) {
    //       await saveDir.create(recursive: true);
    //     }
    //
    //     // 이 경로에 PDF 파일을 저장합니다.
    //     final file = File('$downloadsPath/${name}_회의록.pdf');
    //     await file.writeAsBytes(resp.bodyBytes);
    //
    //     ScaffoldMessenger.of(context)
    //         .showSnackBar(SnackBar(content: Text('PDF 다운로드 완료')));
    //
    //   } else {
    //     ScaffoldMessenger.of(context)
    //         .showSnackBar(SnackBar(content: Text('PDF 다운로드 실패')));
    //   }
    // }
    if (resp.statusCode == 200) {
      final name = widget.name
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
          .replaceAll(' ','_');

      // 👇 여기를 수정해주세요!
      final downloadsDir = await getDownloadsDirectory();
      final downloadsPath = downloadsDir?.path;

      // 만약 다운로드 경로를 찾지 못하면 앱 전용 폴더를 대체 경로로 사용합니다.
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
        // 공용 다운로드 폴더에 파일을 저장합니다.
        final file = File('$downloadsPath/${name}_회의록.pdf');
        if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
        }
        await file.writeAsBytes(resp.bodyBytes);
      }
      // 👆 이 부분을 수정하면 됩니다.

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
      final segs = List<Map<String,dynamic>>.from(data['segments']??[]);
      setState(() {
        segments = segs;
        segKeys = List.generate(segs.length, (_) => GlobalKey());
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
              onPressed: () => Navigator.of(dialogContext).pop(), //  팝업만 닫음
              child: Text('취소',
                style: TextStyle(color: Colors.black),),
            ),
            TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // 1) 검색어 적용
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

              // 2) 결과 없으면 팝업
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
                          onPressed: () => Navigator.of(dialogContext).pop(), // ✅ 팝업만 닫힘
                          child: Text('확인',
                            style: TextStyle(color: Colors.black),),
                        ),
                      ],
                    );
                  },
                );
                return;
              }


              // 3) 결과 있으면 첫 위치로 스크롤
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


            // 회의록 다운로드 버튼
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
            //
            // ExpansionTile(
            //   title: Text('IOS 내부 저장소 viewer TEST',style:TextStyle(fontSize:18,fontWeight:FontWeight.w600)),
            // ),
            //
            // SizedBox(height:20),

            // 화자 비율
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
            // 회의 요약
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
            // 원문: 헤더에만 돋보기·화살표·되돌리기
            ExpansionTile(
              title: Text('원문',style:TextStyle(fontSize:18,fontWeight:FontWeight.w600)),
              initiallyExpanded: isOriginalExpanded,
              onExpansionChanged:(v) => setState(()=>isOriginalExpanded=v),
              tilePadding:EdgeInsets.zero,
              childrenPadding:EdgeInsets.symmetric(vertical:8),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 검색 후에만 보이는 위/아래 꺽쇠
                  if (isOriginalExpanded && matchIdx.isNotEmpty) ...[
                    // 위쪽 꺽쇠 (기존 로직)
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_up),
                      color: Colors.black,
                      onPressed: () {
                        setState(() {
                          if (currentMatch > 0) {
                            currentMatch--;
                          } else {
                            currentMatch = matchIdx.length - 1; // wrap to 마지막
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

                    // ↓ 아래쪽 꺽쇠 (추가된 로직)
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down),
                      color: Colors.black,
                      onPressed: () {
                        setState(() {
                          if (currentMatch < matchIdx.length - 1) {
                            currentMatch++;
                          } else {
                            currentMatch = 0; // wrap to 첫 번째
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

                  // 돋보기
                  if (isOriginalExpanded)
                    IconButton(
                      icon: Icon(Icons.search),
                      color: Colors.black,
                      onPressed: _showSearchDialog,
                    ),

                  // 되돌리기
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

                  // 접기/펼치기
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
                      final timeLabel = formatTime(seg['start']/1000);
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
                                        TextSpan(text:'Speaker ${seg['speaker']} · '),
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
