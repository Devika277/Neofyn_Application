import 'dart:async';

import 'package:flutter/material.dart';

class DebugLogger {
  static final List<String> _logs = [];
  static final _controller = StreamController<List<String>>.broadcast();
  
  static Stream<List<String>> get stream => _controller.stream;
  static List<String> get logs => List.unmodifiable(_logs);

  static void log(String message) {
    final time = DateTime.now().toString().split('.')[0].split(' ')[1];
    final entry = '[$time] $message';
    _logs.add(entry);
    if (_logs.length > 200) _logs.removeAt(0); // keep last 200
    _controller.add(List.unmodifiable(_logs));
    debugPrint(entry); // still prints to console if connected
  }

  static void clear() {
    _logs.clear();
    _controller.add([]);
  }
}