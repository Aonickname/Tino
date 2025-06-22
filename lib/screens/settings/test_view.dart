import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AzureSTTPage extends StatefulWidget {
  const AzureSTTPage({super.key});

  @override
  State<AzureSTTPage> createState() => _AzureSTTPageState();
}

class _AzureSTTPageState extends State<AzureSTTPage> {
  final recorder = FlutterSoundRecorder();
  final channel = WebSocketChannel.connect(
    Uri.parse("ws://34.47.125.249:8000/ws/stt"), // 🔁 실제 서버 IP로 변경
  );

  final StreamController<Uint8List> _audioController = StreamController<Uint8List>();
  bool isRecording = false;
  List<String> transcript = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // WebSocket에서 텍스트 수신
    channel.stream.listen((data) {
      setState(() {
        transcript.add(data.toString());
      });

      // 자동 스크롤 아래로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });

    // 오디오 스트림을 WebSocket으로 전달
    _audioController.stream.listen((buffer) {
      channel.sink.add(buffer); // Uint8List 전송
    });
  }

  Future<void> startRecording() async {
    await Permission.microphone.request();
    if (!(await Permission.microphone.isGranted)) {
      print("🎤 마이크 권한이 없습니다.");
      return;
    }

    await recorder.openRecorder();
    await recorder.startRecorder(
      toStream: _audioController.sink,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );

    setState(() => isRecording = true);
  }

  Future<void> stopRecording() async {
    await recorder.stopRecorder();
    await recorder.closeRecorder();
    await _audioController.close();
    setState(() => isRecording = false);
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    channel.sink.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Azure 실시간 STT")),
      body: Column(
        children: [
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: isRecording ? stopRecording : startRecording,
            child: Text(isRecording ? "⏹ 중지" : "🎙 시작"),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: transcript.length,
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      transcript[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
