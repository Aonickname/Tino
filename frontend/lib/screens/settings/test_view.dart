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

    if (mounted) {
      setState(() => isRecording = true);
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
    if (mounted) {
      setState(() => isRecording = false);
    }
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.meetingName)),
      body: Column(
        children: [
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: isRecording ? stopRecording : startRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecording ? Colors.redAccent : Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: const TextStyle(fontSize: 18),
            ),
            child: Text(isRecording ? "⏹ 녹음 중지" : "🎙 녹음 시작"),
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
                      color: Colors.grey[200],
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