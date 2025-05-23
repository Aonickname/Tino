import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';


class AzureSTTScreen extends StatefulWidget {
  @override
  _AzureSTTScreenState createState() => _AzureSTTScreenState();
}

class _AzureSTTScreenState extends State<AzureSTTScreen> {
  late FlutterSoundRecorder _recorder;
  late WebSocketChannel _channel;
  bool isRecording = false;
  List<String> transcriptList = [];

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    initRecorder();
  }

  Future<void> initRecorder() async {
    await _recorder.openRecorder();
  }

  void startStreaming() async {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://amoeba-national-mayfly.ngrok-free.app/azure-stream'),
    );

    _channel.stream.listen((message) {
      setState(() {
        transcriptList.add(message);
      });
    });

    final controller = StreamController<Uint8List>();

    await _recorder.startRecorder(
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
      toStream: controller.sink,
    );

    controller.stream.listen((chunk) {
      _channel.sink.add(chunk);
    });

    setState(() => isRecording = true);
  }

  void stopStreaming() async {
    await _recorder.stopRecorder();
    _channel.sink.close();
    setState(() => isRecording = false);
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    if (isRecording) _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Azure 실시간 전사')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isRecording ? stopStreaming : startStreaming,
            child: Text(isRecording ? '중지' : '녹음 시작'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transcriptList.length,
              itemBuilder: (context, index) => Container(
                margin: EdgeInsets.all(8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(transcriptList[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}