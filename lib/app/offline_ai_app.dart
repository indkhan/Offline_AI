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
  const OfflineAiApp({
    required this.chatRepository,
    required this.inferenceRepository,
    required this.modelManagerRepository,
    required this.settingsRepository,
    super.key,
  });

  final ChatRepository chatRepository;
  final InferenceRepository inferenceRepository;
  final ModelManagerRepository modelManagerRepository;
  final SettingsRepository settingsRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ChatRepository>.value(value: chatRepository),
        RepositoryProvider<InferenceRepository>.value(
          value: inferenceRepository,
        ),
        RepositoryProvider<ModelManagerRepository>.value(
          value: modelManagerRepository,
        ),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                SettingsCubit(settingsRepository: settingsRepository)..load(),
          ),
          BlocProvider(
            create: (_) => ModelManagerCubit(
              modelManagerRepository: modelManagerRepository,
            )..load(),
          ),
          BlocProvider(
            create: (_) => ChatCubit(
              chatRepository: chatRepository,
              inferenceRepository: inferenceRepository,
              modelManagerRepository: modelManagerRepository,
              settingsRepository: settingsRepository,
            )..initialize(),
          ),
        ],
        child: MaterialApp(
          title: 'Offline AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: const ChatScreen(),
        ),
      ),
    );
  }
}
