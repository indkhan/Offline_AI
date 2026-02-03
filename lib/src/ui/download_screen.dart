import "package:flutter/material.dart";

import "../app_controller.dart";
import "../model_spec.dart";

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Model Download"),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "Download a model to start chatting.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ...kModels.map((spec) => _ModelCard(
                    controller: controller,
                    spec: spec,
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.controller, required this.spec});

  final AppController controller;
  final ModelSpec spec;

  @override
  Widget build(BuildContext context) {
    final status = controller.getModelStatus(spec.id);
    final progress = controller.downloadProgressFor(spec.id);
    final isDownloading = controller.isDownloading(spec.id);
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
                  child: Text(
                    spec.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(spec.sizeLabel),
              ],
            ),
            const SizedBox(height: 8),
            Text(spec.description),
            const SizedBox(height: 12),
            if (progress != null &&
                (progress.phase == DownloadPhase.downloading ||
                    progress.phase == DownloadPhase.verifying)) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.totalBytes == 0
                    ? null
                    : progress.fraction,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!status.isReady)
                  ElevatedButton(
                    onPressed: isDownloading
                        ? null
                        : () => controller.startDownload(spec.id),
                    child: Text(isDownloading ? "Downloading..." : "Download"),
                  ),
                if (status.isReady)
                  ElevatedButton(
                    onPressed: () => controller.deleteModel(spec.id),
                    child: const Text("Delete"),
                  ),
                const SizedBox(width: 12),
                if (status.isReady)
                  const Text(
                    "Installed",
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                if (progress != null &&
                    progress.phase == DownloadPhase.error)
                  const Text(
                    "Download failed",
                    style: TextStyle(color: Colors.redAccent),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
