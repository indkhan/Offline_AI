import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../settings/application/settings_cubit.dart';
import '../application/model_manager_cubit.dart';
import '../application/model_manager_state.dart';
import '../domain/model_info.dart';

class ModelManagerSheet extends StatelessWidget {
  const ModelManagerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<ModelManagerCubit, ModelManagerState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Model Manager',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                for (final model in state.models) ...[
                  _ModelRow(model: model),
                  const Divider(height: 16),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({required this.model});

  final ModelInfo model;

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ModelManagerCubit>();
    final settings = context.watch<SettingsCubit>();
    final state = manager.state.states[model.id] ?? ModelDownloadState.idle;
    final selected = settings.state.selectedModel == model.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                model.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (selected) const Chip(label: Text('Selected')),
          ],
        ),
        if (state.status == DownloadStatus.downloading) ...[
          LinearProgressIndicator(value: state.progress),
          const SizedBox(height: 6),
          Text('${(state.progress * 100).toStringAsFixed(1)}%'),
        ] else if (state.status == DownloadStatus.failed) ...[
          Text(
            state.error ?? 'Download failed',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ] else if (state.status == DownloadStatus.installed) ...[
          const Text('Installed'),
        ] else ...[
          const Text('Not installed'),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (state.status == DownloadStatus.downloading)
              OutlinedButton.icon(
                onPressed: () =>
                    context.read<ModelManagerCubit>().cancel(model.id),
                icon: const Icon(Icons.stop),
                label: const Text('Cancel'),
              )
            else
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<ModelManagerCubit>().download(model),
                icon: const Icon(Icons.download),
                label: Text(
                  state.status == DownloadStatus.installed
                      ? 'Replace'
                      : 'Download',
                ),
              ),
            if (state.status == DownloadStatus.installed)
              OutlinedButton.icon(
                onPressed: () =>
                    context.read<ModelManagerCubit>().delete(model),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            TextButton(
              onPressed: state.status == DownloadStatus.installed
                  ? () => context.read<SettingsCubit>().selectModel(model.id)
                  : null,
              child: const Text('Use this model'),
            ),
          ],
        ),
      ],
    );
  }
}
