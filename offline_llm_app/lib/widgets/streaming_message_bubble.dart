// streaming_message_bubble.dart
// Optimized message bubble that rebuilds ONLY during streaming
// Uses ValueListenableBuilder to isolate rebuilds to this widget only

import 'package:flutter/material.dart';
import '../providers/streaming_message_notifier.dart';
import '../models/chat_message.dart';
import 'chat_bubble.dart';

/// Streaming message bubble - ONLY THIS rebuilds during generation
/// All other messages remain static
class StreamingMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final StreamingMessageNotifier notifier;
  
  const StreamingMessageBubble({
    super.key,
    required this.message,
    required this.notifier,
  });
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: notifier,
      builder: (context, content, child) {
        // Create updated message with streamed content
        final updatedMessage = message.copyWith(content: content);
        
        // Use existing ChatBubble for consistent UI
        return ChatBubble(message: updatedMessage);
      },
    );
  }
}
