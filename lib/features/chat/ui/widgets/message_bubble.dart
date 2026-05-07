import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/chat_message_entity.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool streaming;

  const MessageBubble({super.key, required this.message, this.streaming = false});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            color: AppColors.userBubble,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SelectableText(
            message.content,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15.5, height: 1.4),
          ),
        ),
      );
    }

    final content = message.content.isEmpty && streaming ? '…' : message.content;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MarkdownBody(
        data: content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(color: AppColors.textPrimary, fontSize: 15.5, height: 1.5),
          code: const TextStyle(
            color: AppColors.textPrimary,
            backgroundColor: AppColors.surface,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          codeblockDecoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          codeblockPadding: const EdgeInsets.all(12),
          h1: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
          h2: const TextStyle(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w600),
          h3: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
          listBullet: const TextStyle(color: AppColors.textPrimary, fontSize: 15.5),
          blockquote: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
