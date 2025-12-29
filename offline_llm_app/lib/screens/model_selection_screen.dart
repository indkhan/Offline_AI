// model_selection_screen.dart
// Screen for downloading, selecting, and managing LLM models
// Shows available models with download progress and storage info

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/model_info.dart';
import '../providers/chat_provider.dart';
import '../services/model_manager.dart';

class ModelSelectionScreen extends StatefulWidget {
  const ModelSelectionScreen({super.key});

  @override
  State<ModelSelectionScreen> createState() => _ModelSelectionScreenState();
}

class _ModelSelectionScreenState extends State<ModelSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Models'),
      ),
      body: ListenableBuilder(
        listenable: ModelManager.instance,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStorageInfo(context),
              const SizedBox(height: 16),
              const Text(
                'Available Models',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...AvailableModels.models.map((model) => _buildModelCard(context, model)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStorageInfo(BuildContext context) {
    return FutureBuilder<int>(
      future: ModelManager.instance.getTotalStorageUsed(),
      builder: (context, snapshot) {
        final usedBytes = snapshot.data ?? 0;
        final usedMB = (usedBytes / (1024 * 1024)).toStringAsFixed(1);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.storage,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Storage Used',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '$usedMB MB',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelCard(BuildContext context, ModelInfo model) {
    final modelManager = ModelManager.instance;
    final chatProvider = context.read<ChatProvider>();
    final progress = modelManager.getProgress(model.id);
    final isDownloaded = modelManager.isModelDownloaded(model.id);
    final isActive = chatProvider.currentModelId == model.id;
    final isDownloading = progress.status == ModelStatus.downloading;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            model.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (model.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${model.sizeString} • ${model.quantization}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              model.description,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            
            // Download progress bar
            if (isDownloading) ...[
              LinearProgressIndicator(
                value: progress.progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading... ${progress.progressString}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () => modelManager.cancelDownload(model.id),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ] else ...[
              // Action buttons
              Row(
                children: [
                  if (!isDownloaded)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _downloadModel(model.id),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download'),
                      ),
                    )
                  else if (!isActive) ...[
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _loadModel(context, model.id),
                        child: const Text('Load Model'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showDeleteDialog(context, model),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete model',
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _unloadModel(context),
                        child: const Text('Unload'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showDeleteDialog(context, model),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete model',
                    ),
                  ],
                ],
              ),
            ],
            
            // Error message
            if (progress.status == ModelStatus.error && progress.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  progress.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadModel(String modelId) async {
    try {
      await ModelManager.instance.downloadModel(modelId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> _loadModel(BuildContext context, String modelId) async {
    final chatProvider = context.read<ChatProvider>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading model...'),
          ],
        ),
      ),
    );
    
    final success = await chatProvider.loadModel(modelId);
    
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      
      if (success) {
        Navigator.pop(context); // Go back to chat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model loaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load model: ${chatProvider.error}')),
        );
      }
    }
  }

  Future<void> _unloadModel(BuildContext context) async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.unloadModel();
  }

  void _showDeleteDialog(BuildContext context, ModelInfo model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete model?'),
        content: Text('This will delete ${model.name} and free up ${model.sizeString} of storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ModelManager.instance.deleteModel(model.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
