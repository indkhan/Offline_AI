import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

class Composer extends StatefulWidget {
  final bool streaming;
  final bool enabled;
  final void Function(String) onSend;
  final VoidCallback onStop;

  const Composer({
    super.key,
    required this.streaming,
    required this.enabled,
    required this.onSend,
    required this.onStop,
  });

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final v = _ctrl.text.trim().isNotEmpty;
      if (v != _hasText) setState(() => _hasText = v);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _ctrl.text.trim();
    if (v.isEmpty || !widget.enabled || widget.streaming) return;
    widget.onSend(v);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Shortcuts(
                shortcuts: <LogicalKeySet, Intent>{
                  LogicalKeySet(LogicalKeyboardKey.enter): const _SendIntent(),
                  LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter):
                      const _NewlineIntent(),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    _SendIntent: CallbackAction<_SendIntent>(onInvoke: (_) {
                      _submit();
                      return null;
                    }),
                    _NewlineIntent: CallbackAction<_NewlineIntent>(onInvoke: (_) {
                      final sel = _ctrl.selection;
                      final txt = _ctrl.text;
                      final i = sel.start < 0 ? txt.length : sel.start;
                      final next = '${txt.substring(0, i)}\n${txt.substring(sel.end < 0 ? txt.length : sel.end)}';
                      _ctrl.value = TextEditingValue(
                        text: next,
                        selection: TextSelection.collapsed(offset: i + 1),
                      );
                      return null;
                    }),
                  },
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    minLines: 1,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15.5),
                    decoration: const InputDecoration(
                      hintText: 'Message',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              streaming: widget.streaming,
              enabledSend: _hasText && widget.enabled,
              onSend: _submit,
              onStop: widget.onStop,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendIntent extends Intent {
  const _SendIntent();
}

class _NewlineIntent extends Intent {
  const _NewlineIntent();
}

class _ActionButton extends StatelessWidget {
  final bool streaming;
  final bool enabledSend;
  final VoidCallback onSend;
  final VoidCallback onStop;

  const _ActionButton({
    required this.streaming,
    required this.enabledSend,
    required this.onSend,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    if (streaming) {
      return GestureDetector(
        onTap: onStop,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.stop_rounded, color: AppColors.bg),
        ),
      );
    }
    final active = enabledSend;
    return GestureDetector(
      onTap: active ? onSend : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? AppColors.textPrimary : AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_upward_rounded,
          color: active ? AppColors.bg : AppColors.textSecondary,
        ),
      ),
    );
  }
}
