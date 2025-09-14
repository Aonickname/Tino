import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AzureSTTPage extends StatefulWidget {
  final String meetingName;
  final String meetingDescription;
  final DateTime meetingDate;

  const AzureSTTPage({
    super.key,
    required this.meetingName,
    required this.meetingDescription,
    required this.meetingDate,
  });

  @override
  State<AzureSTTPage> createState() => AzureSTTPageState();
}

class AzureSTTPageState extends State<AzureSTTPage> {
  final recorder = FlutterSoundRecorder();
  late WebSocketChannel channel;
  late StreamController<Uint8List> _audioController;

  bool isRecording = false;
  List<String> transcript = [];
  final ScrollController _scrollController = ScrollController();

  int _seconds = 0;
  Timer? _timer;

  List<double> _waveform = List.generate(50, (index) => 0.0);

  final baseUrl = dotenv.env['AZURE_API_TEST'];

  String get _serverUrl => '$baseUrl/ws/stt';

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    print('🔗 웹소켓 서버에 연결을 시도합니다: $_serverUrl');
    channel = WebSocketChannel.connect(Uri.parse(_serverUrl));

    channel.stream.listen(
          (data) {
        print('✅ 서버로부터 메시지 수신: $data');
        if (mounted) {
          setState(() {
            transcript.add(data.toString());
          });
          _scrollToBottom();
        }
      },
      onError: (error) {
        print('🔥 웹소켓 에러 발생: $error');
        if (mounted) {
          setState(() {
            transcript.add("연결 오류: $error");
            isRecording = false;
          });
        }
      },
      onDone: () {
        print('🔌 웹소켓 연결이 종료되었습니다.');
        if (mounted && isRecording) {
          setState(() => isRecording = false);
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> startRecording() async {
    print("✅ 녹음 시작 버튼 눌림!");
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      print("🎤 마이크 권한이 없어 녹음을 시작할 수 없습니다.");
      return;
    }

    _audioController = StreamController<Uint8List>();
    _audioController.stream.listen((buffer) {
      if (channel.closeCode == null) {
        channel.sink.add(buffer);
      }
    });

    await recorder.openRecorder();
    await recorder.startRecorder(
      toStream: _audioController.sink,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );

    recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
    recorder.onProgress!.listen((e) {
      if (mounted) {
        setState(() {
          final double normalizedValue = (e.decibels ?? -120) * -1 / 120;
          _waveform.add(normalizedValue);
          if (_waveform.length > 50) {
            _waveform.removeAt(0);
          }
        });
      }
    });

    if (mounted) {
      setState(() => isRecording = true);
      _startTimer();
    }
  }

  Future<void> stopRecording() async {
    print("⏹ 녹음 중지 버튼 눌림!");
    await recorder.stopRecorder();
    if (await recorder.isRecording) {
      await recorder.closeRecorder();
    }
    if (!_audioController.isClosed) {
      await _audioController.close();
    }

    _stopTimer();
    setState(() {
      isRecording = false;
      _seconds = 0;
      _waveform = List.generate(50, (index) => 0.0);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds = timer.tick;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    print("화면이 종료되어 리소스를 정리합니다.");
    if (recorder.isRecording) {
      recorder.closeRecorder();
    }
    channel.sink.close();
    if (_audioController.hasListener && !_audioController.isClosed) {
      _audioController.close();
    }
    _stopTimer();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('티노 사용 방법', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '실시간 대화 기록',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: transcript.length,
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      transcript[index],
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: isRecording ? 180 : 150, // 녹음 상태에 따라 높이 조절
            color: Colors.white,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: isRecording
                      ? Column(
                    children: [
                      Container(
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 30,
                              child: SizedBox(
                                width: 150,
                                height: 50,
                                child: CustomPaint(
                                  painter: WaveformPainter(_waveform),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 200,
                              child: Text(
                                '${_seconds.toString().padLeft(2, '0')}s',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
                              ),
                            ),
                            Positioned(
                              right: 80,
                              child: GestureDetector(
                                onTap: stopRecording,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                    border: Border.all(color: Colors.black, width: 2),
                                  ),
                                  child: const Icon(Icons.stop, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 20,
                              child: GestureDetector(
                                onTap: () {
                                  // 일시정지 기능 구현
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[300],
                                    border: Border.all(color: Colors.black, width: 2),
                                  ),
                                  child: const Icon(Icons.pause, color: Colors.black, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildIconButton(Icons.search, '검색', Colors.blueAccent),
                          _buildIconButton(Icons.comment, '의견 물어보기', Colors.blueAccent),
                        ],
                      ),
                    ],
                  )
                      : Center(
                    child: GestureDetector(
                      onTap: startRecording,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.grey[400]!, width: 1),
          ),
          child: Icon(icon, size: 30, color: Colors.blueAccent),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveform;
  WaveformPainter(this.waveform);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;

    final barWidth = size.width / waveform.length;
    for (int i = 0; i < waveform.length; i++) {
      final barHeight = waveform[i] * size.height;
      final x = i * barWidth;
      final y = (size.height - barHeight) / 2;
      canvas.drawLine(Offset(x, y), Offset(x, y + barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}