import 'dart:io';

class DeviceProfile {
  final int contextSize;
  final int numThreads;
  final int gpuLayers;
  const DeviceProfile({
    required this.contextSize,
    required this.numThreads,
    required this.gpuLayers,
  });
}

class ResourceMonitor {
  static DeviceProfile pick() {
    final cores = Platform.numberOfProcessors;
    final threads = cores >= 6 ? 4 : (cores >= 4 ? 2 : 1);
    final gpuLayers = Platform.isIOS || Platform.isMacOS ? 99 : 0;
    return DeviceProfile(
      contextSize: 4096,
      numThreads: threads,
      gpuLayers: gpuLayers,
    );
  }
}
