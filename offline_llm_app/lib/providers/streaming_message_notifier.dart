// streaming_message_notifier.dart
// Dedicated notifier for streaming message updates
// Updates UI at controlled rate (30-60 FPS) without rebuilding entire screen

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Notifier for a single streaming message
/// Only widgets listening to THIS will rebuild during streaming
class StreamingMessageNotifier extends ValueNotifier<String> {
  StreamingMessageNotifier() : super('');
  
  final StringBuffer _buffer = StringBuffer();
  Timer? _updateTimer;
  bool _isDirty = false;
  
  /// Append token to buffer (does NOT trigger update immediately)
  void appendToken(String token) {
    _buffer.write(token);
    _isDirty = true;
    
    // Start update timer if not already running
    _updateTimer ??= Timer.periodic(
      const Duration(milliseconds: 33), // ~30 FPS
      (_) => _flushBuffer(),
    );
  }
  
  /// Flush buffer to UI (triggers rebuild)
  void _flushBuffer() {
    if (_isDirty) {
      value = _buffer.toString();
      _isDirty = false;
    }
  }
  
  /// Force immediate flush and stop timer
  void finalize() {
    _updateTimer?.cancel();
    _updateTimer = null;
    if (_isDirty) {
      value = _buffer.toString();
      _isDirty = false;
    }
  }
  
  /// Clear buffer and reset
  void clear() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _buffer.clear();
    _isDirty = false;
    value = '';
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}
