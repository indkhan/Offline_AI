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
  String _query = '';

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
      backgroundColor: Colors.transparent,
      width: 320,
      child: Container(
        decoration: const BoxDecoration(gradient: AppGradients.scaffold),
        child: SafeArea(
          child: Column(
            children: [
              _Header(onNew: () {
                Navigator.pop(context);
                widget.onNew();
              }),
              _SearchField(
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: FutureBuilder<List<Conversation>>(
                  future: _future,
                  builder: (_, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.violet));
                    }
                    final all = snap.data ?? const [];
                    final list = _query.isEmpty
                        ? all
                        : all
                            .where((c) =>
                                c.title.toLowerCase().contains(_query))
                            .toList();
                    if (list.isEmpty) {
                      return _EmptyHint(query: _query);
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final c = list[i];
                        final active = c.id == widget.activeId;
                        return _HistoryTile(
                          title: c.title,
                          active: active,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onOpen(c.id);
                          },
                          onDelete: () async {
                            await widget.repo.deleteConversation(c.id);
                            _reload();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onNew;
  const _Header({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.accent,
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (r) => AppGradients.accent.createShader(r),
            child: const Text(
              'Offline AI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onNew,
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.glassCard,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.add_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.glassCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Search chats',
            prefixIcon: Icon(Icons.search_rounded,
                color: AppColors.textSecondary, size: 20),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.title,
    required this.active,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: active ? AppGradients.glassCard : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? AppColors.violet.withValues(alpha: 0.45) : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active ? AppGradients.accent : null,
                color: active ? null : AppColors.textTertiary,
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textSecondary, size: 18),
              onPressed: onDelete,
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String query;
  const _EmptyHint({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.glassCard,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.cyan, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'No chats yet' : 'No matches',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              query.isEmpty
                  ? 'Start a new conversation to see it here.'
                  : 'Try a different keyword.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'On-device • Offline',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const Icon(Icons.lock_outline_rounded,
              size: 14, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
