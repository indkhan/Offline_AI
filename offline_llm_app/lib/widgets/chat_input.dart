// chat_input.dart
// Text input widget for chat messages
// Multi-line support with submit on enter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  const ChatInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.enabled = true,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          // Submit on Enter (without Shift)
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              !event.isShiftPressed) {
            onSubmitted?.call(controller.text);
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          maxLines: null,
          textInputAction: TextInputAction.newline,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: enabled ? 'Type a message...' : 'Load a model to chat',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
