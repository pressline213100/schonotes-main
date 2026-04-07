import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FocusTimer extends StatefulWidget {
  const FocusTimer({super.key});

  @override
  State<FocusTimer> createState() => _FocusTimerState();
}

class _FocusTimerState extends State<FocusTimer> {
  bool _isExpanded = false;
  bool _isStopwatch = true; // Default to Stopwatch (计时)
  bool _isRunning = false;
  
  int _seconds = 0; // The active counter
  int _timerSetSeconds = 600; // Default countdown value (10 mins)
  Timer? _timer;

  void _toggleExpanded() => setState(() => _isExpanded = !_isExpanded);

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_isStopwatch) {
          _seconds++; // Count UP
        } else {
          if (_seconds > 0) {
            _seconds--; // Count DOWN
          } else {
            _timer?.cancel();
            _isRunning = false;
            _onFinished();
          }
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() {
      _seconds = _isStopwatch ? 0 : _timerSetSeconds;
    });
  }

  void _onFinished() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Time's up!"), backgroundColor: Colors.orangeAccent)
    );
  }

  String _formatTime(int total) {
    int m = total ~/ 60;
    int s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showSetTimerDialog() {
    if (_isRunning) return;
    
    int minutes = _timerSetSeconds ~/ 60;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Set Timer"),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => minutes = minutes > 1 ? minutes - 1 : 1)),
            Text("$minutes Min", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => minutes++)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () {
            setState(() {
              _timerSetSeconds = minutes * 60;
              if (!_isStopwatch) _seconds = _timerSetSeconds;
            });
            Navigator.pop(ctx);
          }, child: const Text("Set")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isExpanded ? 220 : 60,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(2, 2))],
        border: Border.all(color: _isRunning ? Colors.blueAccent : Colors.grey.shade200, width: 2),
      ),
      child: _isExpanded ? _buildExpanded() : _buildCollapsed(),
    );
  }

  Widget _buildCollapsed() {
    return InkWell(
      onTap: _toggleExpanded,
      child: Center(
        child: Icon(_isStopwatch ? Icons.timer_outlined : Icons.alarm, color: _isRunning ? Colors.blueAccent : Colors.grey, size: 28),
      ),
    );
  }

  Widget _buildExpanded() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(_isStopwatch ? Icons.alarm : Icons.timer_outlined, size: 20, color: Colors.grey),
          onPressed: () {
            if (_isRunning) return;
            setState(() {
              _isStopwatch = !_isStopwatch;
              _resetTimer();
            });
          },
        ),
        GestureDetector(
          onTap: _isStopwatch ? null : _showSetTimerDialog,
          child: Text(
            _formatTime(_seconds),
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: _isStopwatch ? Colors.deepPurple : Colors.blueAccent,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton(
          icon: Icon(_isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 36, color: Colors.blueAccent),
          onPressed: _isRunning ? _pauseTimer : _startTimer,
        ),
        IconButton(
          icon: Icon(Icons.refresh, size: 18, color: Colors.grey.shade400),
          onPressed: _resetTimer,
        ),
      ],
    );
  }
}
