import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";

import "../chat_message.dart";

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final bgColor = isUser ? const Color(0xFF0F5E5E) : const Color(0xFF1E1E1E);
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final margin = isUser
        ? const EdgeInsets.fromLTRB(64, 6, 12, 6)
        : const EdgeInsets.fromLTRB(12, 6, 64, 6);

    return Align(
      alignment: align,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isUser
            ? Text(message.content)
            : MarkdownBody(
                data: message.content,
                selectable: true,
              ),
      ),
    );
  }
}
