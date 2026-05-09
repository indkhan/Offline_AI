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
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            gradient: AppGradients.userBubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SelectableText(
            message.content,
            style: const TextStyle(
                color: Colors.white, fontSize: 15.5, height: 1.4),
          ),
        ),
      );
    }

    final empty = message.content.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AssistantAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                gradient: AppGradients.glassCard,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: empty && streaming
                  ? const _TypingDots()
                  : MarkdownBody(
                      data: message.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15.5,
                            height: 1.5),
                        code: const TextStyle(
                          color: AppColors.cyan,
                          backgroundColor: AppColors.surfaceAlt,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        codeblockPadding: const EdgeInsets.all(12),
                        h1: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w600),
                        h2: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w600),
                        h3: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600),
                        listBullet: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 15.5),
                        blockquote: const TextStyle(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.accent,
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.45),
            blurRadius: 12,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = (_ctrl.value + i * 0.15) % 1.0;
              final s = 0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Opacity(
                  opacity: s,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.accent,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
