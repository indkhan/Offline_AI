import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../model_manager/application/model_manager_cubit.dart';
import '../../model_manager/application/model_manager_state.dart';
import '../../model_manager/ui/model_manager_sheet.dart';
import '../../settings/application/settings_cubit.dart';
import '../../settings/application/settings_state.dart';
import '../application/chat_cubit.dart';
import '../application/chat_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline AI Chat'),
        actions: [
          IconButton(
            tooltip: 'Models',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ModelManagerSheet(),
              );
            },
            icon: const Icon(Icons.memory),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: () => context.read<ChatCubit>().clearConversation(),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _StatusRow(),
            Expanded(
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Install and select a model, then start chatting.',
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final item =
                          state.messages[state.messages.length - 1 - index];
                      final isUser = item.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 640),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.16)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: MarkdownBody(
                            data: item.content.isEmpty ? '...' : item.content,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 6,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Ask something...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (state.isGenerating)
                        IconButton(
                          tooltip: 'Stop',
                          onPressed: () =>
                              context.read<ChatCubit>().stopGeneration(),
                          icon: const Icon(Icons.stop_circle_outlined),
                        )
                      else
                        IconButton(
                          tooltip: 'Send',
                          onPressed: () {
                            final text = _controller.text;
                            _controller.clear();
                            context.read<ChatCubit>().sendMessage(text);
                          },
                          icon: const Icon(Icons.send),
                        ),
                      IconButton(
                        tooltip: 'Regenerate',
                        onPressed: () => context.read<ChatCubit>().regenerate(),
                        icon: const Icon(Icons.refresh),
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
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        return BlocBuilder<ModelManagerCubit, ModelManagerState>(
          builder: (context, modelState) {
            final selected = settingsState.selectedModel;
            final selectedModel = modelState.models
                .where((item) => item.id == selected)
                .firstOrNull;
            final selectedStatus = selected != null
                ? modelState.states[selected]
                : null;
            final installed =
                selectedStatus?.status == DownloadStatus.installed;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectedModel?.displayName ?? 'No model selected'),
                  const SizedBox(height: 4),
                  Text(installed ? 'Installed and ready' : 'Not installed'),
                  BlocBuilder<ChatCubit, ChatState>(
                    builder: (context, chatState) {
                      if (chatState.error != null) {
                        return Text(
                          chatState.error!,
                          style: const TextStyle(color: Colors.redAccent),
                        );
                      }
                      if (chatState.systemNotice != null) {
                        return Text(chatState.systemNotice!);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
