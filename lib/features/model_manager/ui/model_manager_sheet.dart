import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../settings/application/settings_cubit.dart';
import '../../settings/application/settings_state.dart';
import '../application/model_manager_cubit.dart';
import '../application/model_manager_state.dart';

class ModelManagerSheet extends StatelessWidget {
  const ModelManagerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ModelManagerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.borderStrong),
            left: BorderSide(color: AppColors.border),
            right: BorderSide(color: AppColors.border),
          ),
        ),
        child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ShaderMask(
                shaderCallback: (r) => AppGradients.accent.createShader(r),
                child: const Text(
                  'Models',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Download once. Runs offline. Private by design.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ModelManagerCubit, ModelManagerState>(
              builder: (context, state) {
                final entries = state.entries.values.toList();
                return BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, settings) {
                    return ListView.separated(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ModelTile(
                        entry: entries[i],
                        selected: settings.selectedModelId == entries[i].info.id,
                      ),
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

class _ModelTile extends StatelessWidget {
  final ModelEntry entry;
  final bool selected;

  const _ModelTile({required this.entry, required this.selected});

  @override
  Widget build(BuildContext context) {
    final info = entry.info;
    final mb = (info.sizeBytes / (1024 * 1024)).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.glassCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.violet : AppColors.border,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected
                      ? AppGradients.accent
                      : AppGradients.glassCard,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  Icons.memory_rounded,
                  size: 18,
                  color: selected ? Colors.white : AppColors.cyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  info.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.violet, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${info.description}  •  ~$mb MB',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _StatusRow(entry: entry),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final ModelEntry entry;
  const _StatusRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ModelManagerCubit>();
    final settings = context.read<SettingsCubit>();
    switch (entry.status) {
      case ModelStatus.idle:
      case ModelStatus.failed:
        return Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => cubit.download(entry.info),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download'),
            ),
            if (entry.status == ModelStatus.failed) ...[
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Download failed. Tap to retry.',
                  style: TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
            ],
          ],
        );
      case ModelStatus.downloading:
        final mb = entry.totalBytes > 0
            ? '${(entry.receivedBytes / (1024 * 1024)).toStringAsFixed(1)} / ${(entry.totalBytes / (1024 * 1024)).toStringAsFixed(0)} MB'
            : 'starting…';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: entry.progress > 0 ? entry.progress : null,
                minHeight: 8,
                color: AppColors.violet,
                backgroundColor: AppColors.surfaceAlt,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(mb,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const Spacer(),
                TextButton(
                  onPressed: () => cubit.cancel(entry.info.id),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        );
      case ModelStatus.installed:
        final isSelected = settings.state.selectedModelId == entry.info.id;
        return Row(
          children: [
            ElevatedButton.icon(
              onPressed: isSelected ? null : () => settings.select(entry.info.id),
              icon: Icon(isSelected ? Icons.check : Icons.bolt_rounded, size: 18),
              label: Text(isSelected ? 'Selected' : 'Use this'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? AppColors.surfaceHi : AppColors.violet,
                foregroundColor: isSelected ? AppColors.textSecondary : Colors.white,
                disabledBackgroundColor: AppColors.surfaceHi,
                disabledForegroundColor: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: () async {
                final ok = await _confirmDelete(context);
                if (ok != true) return;
                if (isSelected) await settings.clear();
                await cubit.delete(entry.info.id);
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
              label: const Text('Delete', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        );
    }
  }

  Future<bool?> _confirmDelete(BuildContext ctx) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        title: const Text('Delete model?'),
        content: const Text('You can re-download anytime. This frees disk space.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
