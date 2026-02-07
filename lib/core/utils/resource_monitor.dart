import 'dart:io';

class ResourceAdvice {
  const ResourceAdvice({required this.maxTokens, required this.note});

  final int maxTokens;
  final String? note;
}

class ResourceMonitor {
  const ResourceMonitor();

  ResourceAdvice currentAdvice() {
    final processors = Platform.numberOfProcessors;
    if (processors <= 4) {
      return const ResourceAdvice(
        maxTokens: 192,
        note: 'Low-resource device detected. Generation length reduced.',
      );
    }
    return const ResourceAdvice(maxTokens: 384, note: null);
  }
}
