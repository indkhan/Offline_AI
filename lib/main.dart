import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/offline_ai_app.dart';
import 'features/chat/data/chat_repository_impl.dart';
import 'features/inference/data/llama_inference_repository.dart';
import 'features/model_manager/data/model_manager_repository_impl.dart';
import 'features/settings/data/settings_repository_impl.dart';
import 'features/storage/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final documentsDir = await getApplicationDocumentsDirectory();
  final database = AppDatabase(documentsDir.path);
  await database.open();

  runApp(
    OfflineAiApp(
      chatRepository: ChatRepositoryImpl(database: database),
      inferenceRepository: LlamaInferenceRepository(),
      modelManagerRepository: ModelManagerRepositoryImpl(database: database),
      settingsRepository: SettingsRepositoryImpl(database: database),
    ),
  );
}
