import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:typed_data';
import 'dart:async';

class RealtimeSTTWidget extends StatefulWidget {
  @override
  _RealtimeSTTWidgetState createState() => _RealtimeSTTWidgetState();
}

class _RealtimeSTTWidgetState extends State<RealtimeSTTWidget> {
  final recorder = FlutterSoundRecorder();
  final _channel = WebSocketChannel.connect(
    Uri.parse('ws://34.47.125.249:8000/stt'), // 👈 서버 주소로 바꿔!
  );

  late StreamController<Uint8List> audioStreamController;
  bool isRecording = false;
  String transcript = '';

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _listenWebSocket();
    audioStreamController = StreamController<Uint8List>();
  }

  Future<void> _requestPermission() async {
    await Permission.microphone.request();
  }

  void _listenWebSocket() {
    _channel.stream.listen((data) {
      setState(() {
        transcript += data + '\n';
      });
    });
  }

  Future<void> _startRecording() async {
    await recorder.openRecorder();

    audioStreamController = StreamController<Uint8List>();

    await recorder.startRecorder(
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
      toStream: audioStreamController.sink, // ✅ 여기!
    );

    audioStreamController.stream.listen((buffer) {
      _channel.sink.add(buffer); // 서버로 전송
    });

    setState(() {
      isRecording = true;
    });
  }


  Future<void> _stopRecording() async {
    await recorder.stopRecorder();
    await recorder.closeRecorder();
    await audioStreamController.close();

    setState(() {
      isRecording = false;
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    recorder.closeRecorder();
    if (!audioStreamController.isClosed) {
      audioStreamController.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: isRecording ? _stopRecording : _startRecording,
          child: Text(isRecording ? '녹음 중지' : '녹음 시작'),
        ),
        SizedBox(height: 20),
        Text('📝 STT 결과'),
        Expanded(
          child: SingleChildScrollView(
            child: Text(transcript),
          ),
        ),
      ],
    );
  }
}
