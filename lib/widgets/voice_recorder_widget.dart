import 'dart:async';
import 'package:flutter/material.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(int)? onFinish;
  const VoiceRecorderWidget({super.key, this.onFinish});

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _seconds = 0;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _seconds++);
        });
      } else {
        _timer?.cancel();
        if (widget.onFinish != null) widget.onFinish!(_seconds);
      }
    });
  }

  String _formatDuration(int s) {
    int m = s ~/ 60;
    int ss = s % 60;
    return '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic, color: _isRecording ? Colors.red : Colors.blueAccent),
            onPressed: _toggleRecording,
          ),
          if (_isRecording)
            Text(_formatDuration(_seconds), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          if (!_isRecording && _seconds > 0)
            const Text("Saved", style: TextStyle(color: Colors.green, fontSize: 12)),
        ],
      ),
    );
  }
}
