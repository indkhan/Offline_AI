import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../features/chat/application/chat_cubit.dart';
import '../features/chat/domain/chat_repository.dart';
import '../features/chat/ui/chat_screen.dart';
import '../features/inference/domain/inference_repository.dart';
import '../features/model_manager/application/model_manager_cubit.dart';
import '../features/model_manager/domain/model_manager_repository.dart';
import '../features/settings/application/settings_cubit.dart';
import '../features/settings/domain/settings_repository.dart';

class OfflineAiApp extends StatelessWidget {
  final ChatRepository chatRepo;
  final ModelManagerRepository modelRepo;
  final SettingsRepository settingsRepo;
  final InferenceRepository inferenceRepo;

  const OfflineAiApp({
    super.key,
    required this.chatRepo,
    required this.modelRepo,
    required this.settingsRepo,
    required this.inferenceRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ChatRepository>.value(value: chatRepo),
        RepositoryProvider<ModelManagerRepository>.value(value: modelRepo),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepo),
        RepositoryProvider<InferenceRepository>.value(value: inferenceRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit(settingsRepo)..load()),
          BlocProvider(create: (_) => ModelManagerCubit(modelRepo)..load()),
          BlocProvider(
            create: (_) => ChatCubit(
              chatRepo: chatRepo,
              modelRepo: modelRepo,
              inference: inferenceRepo,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Offline AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const ChatScreen(),
        ),
      ),
    );
  }
}
