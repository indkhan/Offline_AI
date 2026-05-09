import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

class Composer extends StatefulWidget {
  final bool streaming;
  final bool enabled;
  final void Function(String) onSend;
  final VoidCallback onStop;
  final VoidCallback onAttachImage;
  final VoidCallback onAttachPdf;
  final VoidCallback onAttachAudio;
  final VoidCallback onVoice;

  const Composer({
    super.key,
    required this.streaming,
    required this.enabled,
    required this.onSend,
    required this.onStop,
    required this.onAttachImage,
    required this.onAttachPdf,
    required this.onAttachAudio,
    required this.onVoice,
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

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttachSheet(
        onImage: () {
          Navigator.pop(context);
          widget.onAttachImage();
        },
        onPdf: () {
          Navigator.pop(context);
          widget.onAttachPdf();
        },
        onAudio: () {
          Navigator.pop(context);
          widget.onAttachAudio();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _hasText && widget.enabled;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            gradient: AppGradients.glassCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _focus.hasFocus
                  ? AppColors.violet.withValues(alpha: 0.55)
                  : AppColors.border,
              width: 1,
            ),
            boxShadow: canSend
                ? [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _IconAction(
                icon: Icons.add_rounded,
                onTap: widget.enabled ? _showAttachSheet : null,
                tooltip: 'Attach',
              ),
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
                        final next =
                            '${txt.substring(0, i)}\n${txt.substring(sel.end < 0 ? txt.length : sel.end)}';
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
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 15.5),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Ask anything…',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
              _IconAction(
                icon: Icons.mic_none_rounded,
                onTap: widget.enabled ? widget.onVoice : null,
                tooltip: 'Voice',
              ),
              const SizedBox(width: 4),
              _SendButton(
                streaming: widget.streaming,
                enabledSend: canSend,
                onSend: _submit,
                onStop: widget.onStop,
              ),
            ],
          ),
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

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  const _IconAction({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Opacity(
          opacity: disabled ? 0.4 : 1,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool streaming;
  final bool enabledSend;
  final VoidCallback onSend;
  final VoidCallback onStop;

  const _SendButton({
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.danger,
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.5),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Icon(Icons.stop_rounded, color: Colors.white),
        ),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: enabledSend ? AppGradients.accent : null,
        color: enabledSend ? null : AppColors.surfaceHi,
        boxShadow: enabledSend
            ? [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.5),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: enabledSend ? onSend : null,
        customBorder: const CircleBorder(),
        child: Icon(
          Icons.arrow_upward_rounded,
          color: enabledSend ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _AttachSheet extends StatelessWidget {
  final VoidCallback onImage;
  final VoidCallback onPdf;
  final VoidCallback onAudio;

  const _AttachSheet({
    required this.onImage,
    required this.onPdf,
    required this.onAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        gradient: AppGradients.glassCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('Attach',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
          _AttachOption(
            icon: Icons.image_rounded,
            tint: AppColors.cyan,
            label: 'Image',
            sub: 'Photo or screenshot',
            onTap: onImage,
          ),
          const SizedBox(height: 8),
          _AttachOption(
            icon: Icons.picture_as_pdf_rounded,
            tint: AppColors.magenta,
            label: 'PDF document',
            sub: 'Ask questions about a file',
            onTap: onPdf,
          ),
          const SizedBox(height: 8),
          _AttachOption(
            icon: Icons.graphic_eq_rounded,
            tint: AppColors.violet,
            label: 'Audio',
            sub: 'Record or upload a clip',
            onTap: onAudio,
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Multimodal features arriving soon.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String sub;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.tint,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.18),
                border: Border.all(color: tint.withValues(alpha: 0.55)),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
