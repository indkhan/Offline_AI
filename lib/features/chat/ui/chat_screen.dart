import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/model_catalog.dart';
import '../../../core/theme/app_theme.dart';
import '../../model_manager/application/model_manager_cubit.dart';
import '../../model_manager/application/model_manager_state.dart';
import '../../model_manager/ui/model_manager_sheet.dart';
import '../../settings/application/settings_cubit.dart';
import '../../settings/application/settings_state.dart';
import '../application/chat_cubit.dart';
import '../application/chat_state.dart';
import '../domain/chat_message_entity.dart';
import '../domain/chat_repository.dart';
import 'widgets/composer.dart';
import 'widgets/history_drawer.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    });
  }

  void _comingSoon(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('$label — coming soon'),
        duration: const Duration(milliseconds: 1400),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        return BlocBuilder<ModelManagerCubit, ModelManagerState>(
          builder: (context, mm) {
            final modelId = settings.selectedModelId;
            final selectedInfo = modelId == null ? null : ModelCatalog.byId(modelId);
            final selectedEntry = modelId == null ? null : mm.entries[modelId];
            final hasInstalled = selectedEntry?.status == ModelStatus.installed;

            return Scaffold(
              extendBodyBehindAppBar: true,
              backgroundColor: AppColors.bg,
              drawer: HistoryDrawer(
                repo: context.read<ChatRepository>(),
                activeId: context.read<ChatCubit>().state.conversation?.id,
                onOpen: (id) => context.read<ChatCubit>().open(id),
                onNew: () => context.read<ChatCubit>().startNew(modelId: modelId),
              ),
              appBar: _GlassAppBar(
                title: selectedInfo?.name ?? 'Choose model',
                online: hasInstalled,
                onTitleTap: () => ModelManagerSheet.show(context),
                onNew: () => context.read<ChatCubit>().startNew(modelId: modelId),
              ),
              body: Container(
                decoration: const BoxDecoration(gradient: AppGradients.scaffold),
                child: Stack(
                  children: [
                    const _AmbientGlow(),
                    BlocConsumer<ChatCubit, ChatState>(
                      listener: (context, state) {
                        if (state.messages.isNotEmpty) _scrollDown();
                        if (state.errorMessage != null) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(
                              content: Text(state.errorMessage!),
                              backgroundColor: AppColors.danger,
                            ));
                        }
                      },
                      builder: (context, state) {
                        return SafeArea(
                          child: Column(
                            children: [
                              Expanded(
                                child: state.messages.isEmpty
                                    ? _EmptyState(
                                        onPickModel: () =>
                                            ModelManagerSheet.show(context),
                                        hasInstalled: hasInstalled,
                                        modelName: selectedInfo?.name,
                                        onPrompt: (p) {
                                          if (selectedInfo == null || !hasInstalled) {
                                            ModelManagerSheet.show(context);
                                            return;
                                          }
                                          context
                                              .read<ChatCubit>()
                                              .send(p, model: selectedInfo);
                                        },
                                      )
                                    : ListView.builder(
                                        controller: _scroll,
                                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                                        itemCount: state.messages.length,
                                        itemBuilder: (_, i) {
                                          final m = state.messages[i];
                                          final streaming =
                                              state.phase == ChatPhase.streaming &&
                                                  i == state.messages.length - 1 &&
                                                  m.role == ChatRole.assistant;
                                          return MessageBubble(
                                              message: m, streaming: streaming);
                                        },
                                      ),
                              ),
                              if (state.messages.isNotEmpty &&
                                  state.phase != ChatPhase.streaming)
                                _RegenerateBar(
                                  enabled: selectedInfo != null && hasInstalled,
                                  onRegenerate: () {
                                    if (selectedInfo == null) return;
                                    context
                                        .read<ChatCubit>()
                                        .regenerate(model: selectedInfo);
                                  },
                                  onClear: () => context.read<ChatCubit>().clear(),
                                ),
                              Composer(
                                streaming: state.phase == ChatPhase.streaming,
                                enabled: selectedInfo != null && hasInstalled,
                                onSend: (text) {
                                  if (selectedInfo == null || !hasInstalled) {
                                    ModelManagerSheet.show(context);
                                    return;
                                  }
                                  context
                                      .read<ChatCubit>()
                                      .send(text, model: selectedInfo);
                                },
                                onStop: () => context.read<ChatCubit>().stop(),
                                onAttachImage: () => _comingSoon('Image upload'),
                                onAttachPdf: () => _comingSoon('PDF upload'),
                                onAttachAudio: () => _comingSoon('Audio input'),
                                onVoice: () => _comingSoon('Voice mode'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool online;
  final VoidCallback onTitleTap;
  final VoidCallback onNew;

  const _GlassAppBar({
    required this.title,
    required this.online,
    required this.onTitleTap,
    required this.onNew,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgTop.withValues(alpha: 0.85),
              AppColors.bgTop.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
      title: GestureDetector(
        onTap: onTitleTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppGradients.glassCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online ? AppColors.success : AppColors.textTertiary,
                  boxShadow: online
                      ? [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.6),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
        ),
      ),
      actions: [
        _CircleIcon(
          icon: Icons.search_rounded,
          onTap: () => _showSearch(context),
          tooltip: 'Search chats',
        ),
        const SizedBox(width: 6),
        _CircleIcon(
          icon: Icons.add_comment_outlined,
          onTap: onNew,
          tooltip: 'New chat',
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _ChatSearchDelegate(),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _CircleIcon({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.glassCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _ChatSearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.textSecondary),
        border: InputBorder.none,
      ),
      textTheme: theme.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }

  @override
  String? get searchFieldLabel => 'Search chats, messages…';

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _searchPlaceholder();

  @override
  Widget buildSuggestions(BuildContext context) => _searchPlaceholder();

  Widget _searchPlaceholder() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.scaffold),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.glassCard,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.history_rounded,
                  color: AppColors.cyan, size: 28),
            ),
            const SizedBox(height: 14),
            const Text('Search across past chats',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Coming soon — full-text search of every conversation.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatefulWidget {
  const _AmbientGlow();

  @override
  State<_AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<_AmbientGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final t = _ctrl.value * 2 * math.pi;
          return Stack(
            children: [
              Positioned(
                top: -120 + 30 * math.sin(t),
                left: -80 + 40 * math.cos(t),
                child: _blob(AppColors.violet.withValues(alpha: 0.45), 320),
              ),
              Positioned(
                bottom: -140 + 25 * math.cos(t),
                right: -100 + 35 * math.sin(t * 1.3),
                child: _blob(AppColors.cyan.withValues(alpha: 0.32), 360),
              ),
              Positioned(
                top: 200 + 20 * math.sin(t * 0.7),
                right: -60,
                child: _blob(AppColors.magenta.withValues(alpha: 0.22), 220),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

class _RegenerateBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onRegenerate;
  final VoidCallback onClear;

  const _RegenerateBar({
    required this.enabled,
    required this.onRegenerate,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      child: Row(
        children: [
          _GhostButton(
            icon: Icons.refresh_rounded,
            label: 'Regenerate',
            onTap: enabled ? onRegenerate : null,
          ),
          const SizedBox(width: 8),
          _GhostButton(
            icon: Icons.delete_outline_rounded,
            label: 'Clear',
            onTap: onClear,
            tint: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? tint;
  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final c = tint ?? AppColors.textPrimary;
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppGradients.glassCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: c),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: c, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasInstalled;
  final String? modelName;
  final VoidCallback onPickModel;
  final void Function(String) onPrompt;

  const _EmptyState({
    required this.hasInstalled,
    required this.modelName,
    required this.onPickModel,
    required this.onPrompt,
  });

  static const _suggestions = <_Suggestion>[
    _Suggestion('Explain quantum entanglement', Icons.science_rounded, AppColors.cyan),
    _Suggestion('Write a haiku about coding', Icons.auto_stories_rounded, AppColors.violet),
    _Suggestion('Plan a 3-day Tokyo trip', Icons.travel_explore_rounded, AppColors.magenta),
    _Suggestion('Debug this stack trace', Icons.bug_report_rounded, AppColors.cyan),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _HeroOrb(),
            const SizedBox(height: 22),
            ShaderMask(
              shaderCallback: (r) => AppGradients.accent.createShader(r),
              child: const Text(
                'How can I help today?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasInstalled
                  ? 'Private. Offline. Running on-device${modelName != null ? ' • $modelName' : ''}.'
                  : 'Pick a model to begin. Everything runs locally.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            if (!hasInstalled)
              _GradientButton(
                icon: Icons.download_rounded,
                label: 'Choose a model',
                onTap: onPickModel,
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.4,
                  children: _suggestions
                      .map((s) => _PromptCard(
                            label: s.label,
                            icon: s.icon,
                            tint: s.tint,
                            onTap: () => onPrompt(s.label),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 18),
            const _CapabilityRow(),
          ],
        ),
      ),
    );
  }
}

class _Suggestion {
  final String label;
  final IconData icon;
  final Color tint;
  const _Suggestion(this.label, this.icon, this.tint);
}

class _HeroOrb extends StatefulWidget {
  const _HeroOrb();

  @override
  State<_HeroOrb> createState() => _HeroOrbState();
}

class _HeroOrbState extends State<_HeroOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = _ctrl.value * 2 * math.pi;
        final pulse = 1 + 0.06 * math.sin(t);
        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: pulse,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.violet.withValues(alpha: 0.55),
                        AppColors.violet.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.rotate(
                angle: t,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.cyan,
                        AppColors.violet,
                        AppColors.magenta,
                        AppColors.cyan,
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bg,
                  border: Border.all(color: AppColors.borderStrong),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome,
                    color: AppColors.cyan, size: 32),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  const _PromptCard({
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppGradients.glassCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.18),
                border: Border.all(color: tint.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13.5, height: 1.25),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GradientButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppGradients.accent,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: const [
        _CapPill(icon: Icons.image_outlined, label: 'Images'),
        _CapPill(icon: Icons.picture_as_pdf_outlined, label: 'PDFs'),
        _CapPill(icon: Icons.mic_none_rounded, label: 'Voice'),
        _CapPill(icon: Icons.history_rounded, label: 'Chat history'),
      ],
    );
  }
}

class _CapPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CapPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppGradients.glassCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
