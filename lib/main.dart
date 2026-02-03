import "package:flutter/material.dart";

import "src/app_controller.dart";
import "src/model_spec.dart";
import "src/ui/chat_screen.dart";
import "src/ui/download_screen.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OfflineAiApp());
}

class OfflineAiApp extends StatefulWidget {
  const OfflineAiApp({super.key});

  @override
  State<OfflineAiApp> createState() => _OfflineAiAppState();
}

class _OfflineAiAppState extends State<OfflineAiApp> {
  late final AppController _controller;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    _initFuture = _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Offline AI",
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A3A3),
          brightness: Brightness.dark,
        ),
      ),
      home: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final defaultReady = _controller
                  .getModelStatus(ModelId.qwen)
                  .isReady;
              return defaultReady
                  ? ChatScreen(controller: _controller)
                  : DownloadScreen(controller: _controller);
            },
          );
        },
      ),
    );
  }
}
