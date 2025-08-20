import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class RecordScreen extends StatefulWidget {
  final String meetingName;
  final String meetingDescription;
  final DateTime meetingDate;

  const RecordScreen({
    Key? key,
    required this.meetingName,
    required this.meetingDescription,
    required this.meetingDate,
  }) : super(key: key);

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late FlutterSoundRecorder _recorder;
  late WebSocketChannel _channel;
  bool isRecording = false;
  List<String> transcriptList = [];
  String? recordedFilePath;

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

    final streamUrl = dotenv.env['AZURE_STREAM_URL'];

    _channel = WebSocketChannel.connect(
      Uri.parse(streamUrl!),
    );

    _channel.stream.listen((message) {
      setState(() {
        transcriptList.add(message);
      });
    });

    final controller = StreamController<Uint8List>();

    final dir = await getExternalStorageDirectory();
    final recordingsDir = Directory('${dir!.path}/recordings');

    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    recordedFilePath = '${recordingsDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.startRecorder(
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
      numChannels: 1,
      toStream: controller.sink,
      toFile: recordedFilePath,
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

    if (recordedFilePath != null) {
      print("녹음 파일 저장 완료: $recordedFilePath");
      // TODO: 서버 업로드 함수 연동 가능
    }
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
      appBar: AppBar(title: Text('실시간 자막 보기')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    transcriptList.join(" "),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isRecording ? null : startStreaming,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('녹음 시작'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: isRecording ? stopStreaming : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('중지'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}