// main.dart
// Entry point for the Offline LLM Chat application
// Initializes services and sets up providers

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/theme_provider.dart';
import 'services/model_manager.dart';
import 'config/app_theme.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to portrait mode for better UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize model manager
  await ModelManager.instance.initialize();
  
  runApp(const OfflineLLMApp());
}

class OfflineLLMApp extends StatelessWidget {
  const OfflineLLMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => ConversationProvider()..initialize(),
        ),
        ChangeNotifierProxyProvider<ConversationProvider, ChatProvider>(
          create: (context) {
            final chatProvider = ChatProvider();
            chatProvider.setConversationProvider(
              context.read<ConversationProvider>(),
            );
            chatProvider.initialize();
            return chatProvider;
          },
          update: (context, conversationProvider, chatProvider) {
            chatProvider?.setConversationProvider(conversationProvider);
            return chatProvider ?? ChatProvider();
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Offline LLM',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.materialThemeMode,
            home: const ChatScreen(),
          );
        },
      ),
    );
  }
}
