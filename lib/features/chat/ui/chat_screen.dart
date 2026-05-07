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
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
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
              backgroundColor: AppColors.bg,
              drawer: HistoryDrawer(
                repo: context.read<ChatRepository>(),
                activeId: context.read<ChatCubit>().state.conversation?.id,
                onOpen: (id) => context.read<ChatCubit>().open(id),
                onNew: () => context.read<ChatCubit>().startNew(modelId: modelId),
              ),
              appBar: AppBar(
                title: GestureDetector(
                  onTap: () => ModelManagerSheet.show(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedInfo?.name ?? 'Choose model',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more, size: 20),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_comment_outlined),
                    tooltip: 'New chat',
                    onPressed: () =>
                        context.read<ChatCubit>().startNew(modelId: modelId),
                  ),
                ],
              ),
              body: BlocConsumer<ChatCubit, ChatState>(
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
                  return Column(
                    children: [
                      Expanded(
                        child: state.messages.isEmpty
                            ? _EmptyState(
                                onPickModel: () => ModelManagerSheet.show(context),
                                hasInstalled: hasInstalled,
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
                                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                                itemCount: state.messages.length,
                                itemBuilder: (_, i) {
                                  final m = state.messages[i];
                                  final streaming =
                                      state.phase == ChatPhase.streaming &&
                                          i == state.messages.length - 1 &&
                                          m.role == ChatRole.assistant;
                                  return MessageBubble(message: m, streaming: streaming);
                                },
                              ),
                      ),
                      if (state.messages.isNotEmpty &&
                          state.phase != ChatPhase.streaming)
                        _RegenerateBar(
                          enabled: selectedInfo != null && hasInstalled,
                          onRegenerate: () {
                            if (selectedInfo == null) return;
                            context.read<ChatCubit>().regenerate(model: selectedInfo);
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
                          context.read<ChatCubit>().send(text, model: selectedInfo);
                        },
                        onStop: () => context.read<ChatCubit>().stop(),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
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
          OutlinedButton.icon(
            onPressed: enabled ? onRegenerate : null,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Regenerate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasInstalled;
  final VoidCallback onPickModel;
  final void Function(String) onPrompt;

  const _EmptyState({
    required this.hasInstalled,
    required this.onPickModel,
    required this.onPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.accent, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'What can I help with?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              hasInstalled
                  ? 'Offline. Private. On-device inference.'
                  : 'Pick and download a model to start.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!hasInstalled)
              ElevatedButton.icon(
                onPressed: onPickModel,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Choose a model'),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _Chip('Explain quantum entanglement', onPrompt),
                  _Chip('Write a haiku about coding', onPrompt),
                  _Chip('Plan a 3-day trip to Tokyo', onPrompt),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final void Function(String) onTap;
  const _Chip(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5)),
      ),
    );
  }
}
