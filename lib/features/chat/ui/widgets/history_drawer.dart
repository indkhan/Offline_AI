import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/chat_message_entity.dart';
import '../../domain/chat_repository.dart';

class HistoryDrawer extends StatefulWidget {
  final ChatRepository repo;
  final String? activeId;
  final void Function(String) onOpen;
  final VoidCallback onNew;

  const HistoryDrawer({
    super.key,
    required this.repo,
    required this.activeId,
    required this.onOpen,
    required this.onNew,
  });

  @override
  State<HistoryDrawer> createState() => _HistoryDrawerState();
}

class _HistoryDrawerState extends State<HistoryDrawer> {
  late Future<List<Conversation>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.listConversations();
  }

  void _reload() => setState(() {
        _future = widget.repo.listConversations();
      });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surfaceAlt,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Text('Chats',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onNew();
                    },
                    icon: const Icon(Icons.add, color: AppColors.textPrimary),
                    tooltip: 'New chat',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Conversation>>(
                future: _future,
                builder: (_, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snap.data ?? const [];
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('No chats yet',
                          style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final c = list[i];
                      final active = c.id == widget.activeId;
                      return ListTile(
                        title: Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        tileColor: active ? AppColors.surface : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.textSecondary, size: 20),
                          onPressed: () async {
                            await widget.repo.deleteConversation(c.id);
                            _reload();
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onOpen(c.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
