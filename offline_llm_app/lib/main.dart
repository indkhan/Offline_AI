// main.dart
// Entry point for the Offline LLM Chat application
// Initializes services and sets up providers

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/conversation_provider.dart';
import 'services/model_manager.dart';
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
      child: MaterialApp(
        title: 'Offline LLM',
        debugShowCheckedModeBanner: false,
        
        // Light theme
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10A37F), // ChatGPT green
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
        ),
        
        // Dark theme
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10A37F),
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
        ),
        
        themeMode: ThemeMode.system,
        home: const ChatScreen(),
      ),
    );
  }
}
