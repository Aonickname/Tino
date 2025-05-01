import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class RecordScreen extends StatefulWidget {
  final String meetingName;
  final String meetingDescription;
  final DateTime meetingDate;

  const RecordScreen({
    required this.meetingName,
    required this.meetingDescription,
    required this.meetingDate,
  });

  @override
  _RecordScreenState createState() => _RecordScreenState();
}


class _RecordScreenState extends State<RecordScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "음성 인식 대기 중...";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _startListening();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _text = val.recognizedWords;
        }),
        listenMode: stt.ListenMode.dictation,
      );
    } else {
      setState(() => _isListening = false);
      print("음성 인식 불가");
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회의 녹음')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_text, style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? '인식 중지' : '다시 시작'),
            ),
          ],
        ),
      ),
    );
  }
}
