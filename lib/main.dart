import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/offline_ai_app.dart';
import 'features/chat/data/chat_repository_impl.dart';
import 'features/inference/data/fllama_inference_repository.dart';
import 'features/model_manager/data/model_manager_repository_impl.dart';
import 'features/settings/data/settings_repository_impl.dart';
import 'features/storage/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF212121),
    ),
  );

  final database = AppDatabase();
  await database.init();

  final chatRepo = ChatRepositoryImpl(database.db);
  final modelRepo = ModelManagerRepositoryImpl(database.db);
  final settingsRepo = SettingsRepositoryImpl();
  final inferenceRepo = FllamaInferenceRepository();

  runApp(OfflineAiApp(
    chatRepo: chatRepo,
    modelRepo: modelRepo,
    settingsRepo: settingsRepo,
    inferenceRepo: inferenceRepo,
  ));
}
