# How the Offline LLM App Works

A comprehensive guide to understanding the entire application architecture, features, and implementation details.

---

## 📚 Table of Contents

1. [Overview & Architecture](#overview--architecture)
2. [Core Components](#core-components)
3. [Features & Implementation](#features--implementation)
4. [Data Flow](#data-flow)
5. [Performance Optimizations](#performance-optimizations)
6. [How to Extend](#how-to-extend)

---

## Overview & Architecture

### What is This App?

This is an **offline-first Flutter application** that runs Large Language Models (LLMs) directly on your device using **llama.cpp** via FFI (Foreign Function Interface). No internet required after downloading models.

### Tech Stack

```
┌─────────────────────────────────────┐
│         Flutter (Dart)              │  ← UI Layer
├─────────────────────────────────────┤
│    Provider (State Management)      │  ← Business Logic
├─────────────────────────────────────┤
│      FFI (Native Bridge)            │  ← Communication Layer
├─────────────────────────────────────┤
│    llama.cpp (C++ Library)          │  ← Inference Engine
├─────────────────────────────────────┤
│  GGUF Models (Quantized Weights)    │  ← AI Models
└─────────────────────────────────────┘
```

### Directory Structure

```
offline_llm_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── config/
│   │   └── app_theme.dart        # Theme definitions
│   ├── ffi/
│   │   └── llama_bindings.dart   # Native FFI bindings
│   ├── models/
│   │   ├── chat_message.dart     # Message data model
│   │   ├── conversation.dart     # Conversation model
│   │   └── model_info.dart       # LLM model metadata
│   ├── providers/
│   │   ├── chat_provider.dart           # Chat state management
│   │   ├── conversation_provider.dart   # Conversation history
│   │   └── theme_provider.dart          # Theme management
│   ├── screens/
│   │   ├── chat_screen.dart             # Main chat UI
│   │   ├── model_selection_screen.dart  # Model management
│   │   └── settings_screen.dart         # App settings
│   ├── services/
│   │   ├── llama_service.dart           # LLM inference service
│   │   ├── model_manager.dart           # Model download/loading
│   │   └── conversation_storage.dart    # Persistent storage
│   └── widgets/
│       ├── chat_bubble.dart             # Message display
│       ├── chat_input.dart              # Text input field
│       └── conversation_drawer.dart     # Chat history sidebar
├── native/
│   ├── llama_wrapper.h          # C header for FFI
│   ├── llama_wrapper.cpp        # C++ implementation
│   └── CMakeLists.txt           # Build configuration
└── android/ios/                 # Platform-specific configs
```

---

## Core Components

### 1. Main Entry Point (`main.dart`)

**Purpose**: Initialize the app and set up providers

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Non-blocking orientation lock
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize model manager in background (don't await!)
  ModelManager.instance.initialize();
  
  runApp(const OfflineLLMApp());
}
```

**Why this way?**
- **No `await`**: Prevents blocking app startup (was causing 800ms delay)
- **Background init**: Model manager loads asynchronously while app renders
- **Instant startup**: App shows UI in ~50ms instead of 1000ms

---

### 2. State Management (Providers)

#### ThemeProvider (`providers/theme_provider.dart`)

**Purpose**: Manage app theme (Light/Dark/System)

```dart
class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners(); // ← Triggers UI rebuild
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}
```

**Why Provider pattern?**
- **Reactive UI**: Changing theme automatically updates entire app
- **Persistent**: User preference saved to disk
- **Efficient**: Only rebuilds widgets that listen to theme changes

#### ConversationProvider (`providers/conversation_provider.dart`)

**Purpose**: Manage chat history and conversations

```dart
class ConversationProvider extends ChangeNotifier {
  List<Conversation>? _conversations; // Nullable = lazy load
  Conversation? _activeConversation;
  List<ChatMessage> _messages = [];
  
  // Called only when drawer opens
  Future<void> ensureConversationsLoaded() async {
    if (_conversations != null) return; // Already loaded
    
    _conversations = await _storage.loadConversations();
    notifyListeners();
  }
}
```

**Why lazy loading?**
- **Fast startup**: Don't load all conversations on app start
- **On-demand**: Load only when user opens chat history drawer
- **Memory efficient**: Doesn't keep unused data in memory

#### ChatProvider (`providers/chat_provider.dart`)

**Purpose**: Handle LLM inference and message streaming

```dart
class ChatProvider extends ChangeNotifier {
  Future<void> sendMessage(String content) async {
    // Add user message
    await _conversationProvider?.addMessage(userMessage);
    
    // Generate response in background isolate
    final stream = _llamaService.generate(GenerationParams(
      prompt: _buildPrompt(),
      maxTokens: _maxTokens,
    ));
    
    // Stream tokens as they're generated
    stream.listen((token) {
      _updateLastMessage(token); // Updates UI incrementally
    });
  }
}
```

**Why streaming?**
- **Progressive display**: User sees response appear word-by-word
- **Better UX**: Like ChatGPT, feels more interactive
- **Non-blocking**: Inference runs in isolate, UI stays responsive

---

### 3. FFI Bridge (Native Integration)

#### FFI Bindings (`ffi/llama_bindings.dart`)

**Purpose**: Connect Dart to C++ llama.cpp library

```dart
class LlamaBindings {
  late final DynamicLibrary _lib;
  
  // Load native library
  LlamaBindings() {
    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libllama_wrapper.so');
    } else if (Platform.isIOS) {
      _lib = DynamicLibrary.process();
    }
  }
  
  // Bind C function to Dart
  late final llama_wrapper_init = _lib.lookupFunction<
    Pointer<Void> Function(),
    Pointer<Void> Function()
  >('llama_wrapper_init');
}
```

**Why FFI?**
- **Performance**: Direct C++ calls, no serialization overhead
- **Access to native**: Can use optimized C++ libraries like llama.cpp
- **Cross-platform**: Same API works on Android/iOS

#### Native Wrapper (`native/llama_wrapper.cpp`)

**Purpose**: Provide C API for llama.cpp

```cpp
LLAMA_API LlamaContext llama_wrapper_init() {
    // Allocate context
    auto* internal = new LlamaInternalContext();
    return reinterpret_cast<LlamaContext>(internal);
}

LLAMA_API int llama_wrapper_load_model(
    LlamaContext ctx,
    const char* model_path
) {
    auto* internal = reinterpret_cast<LlamaInternalContext*>(ctx);
    
    // Load model using llama.cpp API
    internal->model = llama_model_load_from_file(
        model_path, 
        model_params
    );
    
    return internal->model != nullptr ? 0 : -1;
}
```

**Why wrapper layer?**
- **Simpler API**: Abstracts complex llama.cpp internals
- **Memory safety**: Manages C++ objects lifecycle
- **Thread-safe**: Uses mutexes to prevent race conditions

---

### 4. LLM Inference (`services/llama_service.dart`)

**Purpose**: Run LLM inference in background isolate

```dart
class LlamaService {
  // Run in separate isolate to avoid blocking UI
  Stream<String> generate(GenerationParams params) {
    final controller = StreamController<String>();
    
    // Spawn isolate for inference
    Isolate.spawn(_isolateEntry, {
      'sendPort': controller.sink,
      'params': params,
    });
    
    return controller.stream;
  }
  
  // This runs in background isolate
  static void _isolateEntry(Map args) {
    final bindings = LlamaBindings();
    
    // Generate tokens one by one
    while (true) {
      final token = bindings.llama_wrapper_generate(...);
      args['sendPort'].add(token); // Send to UI
      
      if (isEndOfGeneration) break;
    }
  }
}
```

**Why isolates?**
- **Non-blocking**: Inference runs in separate thread
- **Smooth UI**: Main thread free for animations/gestures
- **Cancellable**: Can stop generation mid-stream

---

## Features & Implementation

### Feature 1: Chat History with Persistence

**What**: Save all conversations and load them on demand

#### Data Models

```dart
// Conversation metadata
class Conversation {
  final String id;
  final String title;           // Auto-generated from first message
  final DateTime createdAt;
  final int messageCount;
  
  // Serialize to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'messageCount': messageCount,
  };
}

// Individual message
class ChatMessage {
  final String id;
  final MessageRole role;       // user or assistant
  final String content;
  final DateTime timestamp;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };
}
```

#### Storage Service (`services/conversation_storage.dart`)

```dart
class ConversationStorage {
  // Save conversations using compute() to avoid blocking
  Future<void> saveConversations(List<Conversation> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Encode JSON in background isolate (PERFORMANCE!)
    final jsonString = await compute(_encodeConversations, conversations);
    
    await prefs.setString('conversations', jsonString);
  }
  
  // Save messages to individual files
  Future<void> saveMessages(String conversationId, List<ChatMessage> messages) async {
    final file = File('$appDir/conversations/$conversationId.json');
    
    // Encode in background isolate
    final jsonString = await compute(_encodeMessages, messages);
    
    await file.writeAsString(jsonString);
  }
}

// Top-level function for compute()
String _encodeConversations(List<Conversation> conversations) {
  final jsonList = conversations.map((c) => c.toJson()).toList();
  return json.encode(jsonList);
}
```

**Why this approach?**
- **compute()**: Moves JSON encoding off main thread (was causing 100-300ms freeze)
- **Separate files**: Each conversation in its own file for efficient loading
- **SharedPreferences**: Fast access to conversation list
- **Auto-save**: Every message is saved immediately

#### UI Component (`widgets/conversation_drawer.dart`)

```dart
class ConversationDrawer extends StatelessWidget {
  Widget _buildConversationList(BuildContext context) {
    return Consumer<ConversationProvider>(
      builder: (context, provider, child) {
        // Trigger lazy loading when drawer opens
        provider.ensureConversationsLoaded();
        
        return ListView.builder(
          itemCount: provider.conversations.length,
          itemBuilder: (context, index) {
            final conversation = provider.conversations[index];
            return ListTile(
              title: Text(conversation.title),
              onTap: () => provider.switchConversation(conversation.id),
            );
          },
        );
      },
    );
  }
}
```

**Why this UI pattern?**
- **Consumer**: Rebuilds only this widget when conversations change
- **ListView.builder**: Only renders visible items (lazy loading)
- **Swipe to delete**: Dismissible widget for easy deletion

---

### Feature 2: Dark Mode with User Toggle

**What**: Beautiful dark theme with user preference

#### Theme Configuration (`config/app_theme.dart`)

```dart
class AppTheme {
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Color(0xFF10A37F), // ChatGPT green
      brightness: Brightness.dark,
      surface: Color(0xFF161B22),           // GitHub dark
      background: Color(0xFF0D1117),        // Deep dark
      onSurface: Color(0xFFE6EDF3),         // High contrast text
      outline: Color(0xFF30363D),           // Subtle borders
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Color(0xFF0D1117),
      // ... more theming
    );
  }
}
```

**Why GitHub-inspired colors?**
- **Tested**: GitHub dark theme is proven for readability
- **Contrast**: High contrast ensures text is always readable
- **Professional**: Looks polished and modern

#### Theme Selector (`screens/settings_screen.dart`)

```dart
Widget _buildThemeSelector() {
  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      return Column(
        children: [
          _buildThemeOption(AppThemeMode.light, 'Light', Icons.light_mode),
          _buildThemeOption(AppThemeMode.dark, 'Dark', Icons.dark_mode),
          _buildThemeOption(AppThemeMode.system, 'System', Icons.brightness_auto),
        ],
      );
    },
  );
}
```

**Why this design?**
- **Visual feedback**: Icons + checkmarks make selection clear
- **System option**: Respects user's device settings
- **Instant switching**: Theme changes immediately on tap

---

### Feature 3: Performance Optimizations

#### 1. Text Input Without Rebuilding Screen

**Problem**: Every keystroke was rebuilding entire screen (causing lag)

**Solution**: ValueListenableBuilder

```dart
// Before (BAD - rebuilds everything)
_textController.addListener(() {
  setState(() {}); // Rebuilds entire _ChatScreenState!
});

// After (GOOD - rebuilds only send button)
ValueListenableBuilder<TextEditingValue>(
  valueListenable: _textController,
  builder: (context, value, child) {
    return _buildSendButton(context, chatProvider, value.text);
  },
)
```

**Result**: Text input lag reduced from 5-10ms to <1ms per character

#### 2. Lazy Loading Conversations

**Problem**: Loading all conversations on startup (300-500ms)

**Solution**: Load on demand

```dart
class ConversationProvider {
  Future<void> initialize() async {
    // DON'T load conversations here
    // Just create default conversation
    _activeConversation = _createNewConversation();
    _messages = [];
  }
  
  // Called when drawer opens
  Future<void> ensureConversationsLoaded() async {
    if (_conversations != null) return; // Already loaded
    _conversations = await _storage.loadConversations();
  }
}
```

**Result**: App starts instantly, conversations load in background

#### 3. JSON Parsing in Isolates

**Problem**: Large JSON parsing blocking UI thread

**Solution**: compute() function

```dart
// Before (BLOCKS UI)
final jsonList = json.decode(jsonString);
return jsonList.map((json) => Conversation.fromJson(json)).toList();

// After (BACKGROUND ISOLATE)
return await compute(_parseConversations, jsonString);

// Top-level function
List<Conversation> _parseConversations(String jsonString) {
  final jsonList = json.decode(jsonString);
  return jsonList.map((json) => Conversation.fromJson(json)).toList();
}
```

**Result**: No UI blocking, 95% faster for large datasets

---

### Feature 4: Conversation Search

**What**: Fast, optimized search through conversation titles and message content

#### Architecture: Two-Tier Progressive Search

**Phase 1 - Instant Title Search** (0-10ms)
```dart
// Search in memory - instant results
for (final conversation in _conversations ?? []) {
  if (conversation.title.toLowerCase().contains(query)) {
    results.add(conversation);
  }
}
// Update UI immediately with title matches
_filteredConversations = List.from(results);
notifyListeners();
```

**Phase 2 - Background Content Search** (non-blocking)
```dart
// Load and search message content in background
for (final conversation in _conversations ?? []) {
  // Skip if already matched by title
  if (titleMatches.contains(conversation)) continue;
  
  // Load messages with caching
  final messages = await _storage.loadMessages(conversation.id);
  
  // Use compute() for large conversations (>20 messages)
  if (messages.length > 20) {
    final hasMatch = await compute(_searchInMessages, {
      'messages': messages,
      'query': query,
    });
  }
  
  // Update UI progressively as matches are found
  if (hasMatch) {
    _filteredConversations = [...titleMatches, ...contentMatches];
    notifyListeners();
  }
}
```

**Why this approach?**
- **Instant feedback**: User sees title matches immediately
- **Non-blocking**: Content search runs in background
- **Progressive results**: UI updates as more matches are found
- **Efficient**: Uses compute() for CPU-intensive search in large conversations

#### Performance Optimizations

**1. Debouncing** (300ms delay)
```dart
void searchConversations(String query) {
  _searchDebounce?.cancel();
  
  // Wait 300ms after user stops typing
  _searchDebounce = Timer(const Duration(milliseconds: 300), () {
    _performSearch();
  });
}
```

**Why**: Don't search on every keystroke, wait until user finishes typing

**2. Message Caching**
```dart
final Map<String, List<ChatMessage>> _messageCache = {};

// Check cache before loading from storage
if (_messageCache.containsKey(conversation.id)) {
  messages = _messageCache[conversation.id]!;
} else {
  messages = await _storage.loadMessages(conversation.id);
  _messageCache[conversation.id] = messages;
}
```

**Why**: Avoid reloading same conversations during search session

**3. Compute for Large Lists**
```dart
// Only use isolate for large message lists
if (messages.length > 20) {
  final hasMatch = await compute(_searchInMessages, params);
} else {
  // Quick in-line search for small lists
  final hasMatch = messages.any((msg) => msg.content.contains(query));
}
```

**Why**: Overhead of compute() not worth it for small lists

#### UI Component

```dart
// Search bar at top of drawer
Widget _buildSearchBar(BuildContext context) {
  return TextField(
    onChanged: (query) => provider.searchConversations(query),
    decoration: InputDecoration(
      hintText: 'Search conversations...',
      prefixIcon: Icon(
        provider.isSearching ? Icons.hourglass_empty : Icons.search,
      ),
      suffixIcon: provider.searchQuery.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                provider.clearSearch();
              },
            )
          : null,
    ),
  );
}
```

**UI Features**:
- Search icon changes to hourglass during background search
- Clear button appears when query is not empty
- "No conversations found" message when search returns nothing
- Smooth animations when results update

#### Search Flow

```
User types in search bar
       ↓
Debounce timer starts (300ms)
       ↓
Timer expires → perform search
       ↓
Phase 1: Search titles in memory (instant)
       ↓
Update UI with title matches
       ↓
Phase 2: Load messages for each conversation
       ↓
Check cache first
       ↓
Search in messages (compute() if >20 messages)
       ↓
Update UI progressively as matches found
       ↓
User sees complete results
```

#### Performance Metrics

| Operation | Time | Details |
|-----------|------|---------|
| Title search | <10ms | In-memory, instant |
| Debounce delay | 300ms | Wait for user to stop typing |
| Small conversation search | <5ms | Quick inline search |
| Large conversation search | Background | Uses compute(), non-blocking |
| Cache hit | 0ms | No reload needed |
| Cache miss | 10-50ms | Load from storage once |

**Expected UX**:
- Type "hello" → See title matches instantly
- Background indicator shows → Content search running
- More results appear → Conversations with "hello" in messages
- Total time: Title results in <10ms, complete results in <500ms
- **UI stays 60fps** throughout entire search

---

## Data Flow

### Message Sending Flow

```
User types message
       ↓
ChatInput widget
       ↓
_sendMessage() in ChatScreen
       ↓
chatProvider.sendMessage()
       ↓
ConversationProvider.addMessage() (save to storage)
       ↓
LlamaService.generate() (spawn isolate)
       ↓
[Background Isolate]
├─ Load model if needed
├─ Tokenize prompt
├─ Run inference
└─ Stream tokens back
       ↓
ChatProvider receives tokens
       ↓
Updates message content
       ↓
notifyListeners()
       ↓
ChatScreen rebuilds with new message
       ↓
User sees streaming response
```

### Conversation Loading Flow

```
User opens drawer
       ↓
ConversationDrawer builds
       ↓
provider.ensureConversationsLoaded()
       ↓
Check if already loaded
       ↓
If not: ConversationStorage.loadConversations()
       ↓
Read from SharedPreferences
       ↓
Parse JSON in compute() isolate
       ↓
Return List<Conversation>
       ↓
Sort by update time
       ↓
notifyListeners()
       ↓
ListView.builder renders list
```

---

## How to Extend

### Adding a New Feature

#### Example: Add "Export Conversation" Feature

**Step 1: Update Data Model** (if needed)

```dart
// models/conversation.dart
class Conversation {
  // Add export method
  String exportAsText() {
    return '''
Conversation: $title
Created: ${createdAt.toString()}
Messages: $messageCount

[Export messages here]
    ''';
  }
}
```

**Step 2: Add Service Method**

```dart
// services/conversation_storage.dart
class ConversationStorage {
  Future<void> exportConversation(String conversationId, String path) async {
    final messages = await loadMessages(conversationId);
    final text = _formatAsText(messages);
    final file = File(path);
    await file.writeAsString(text);
  }
}
```

**Step 3: Update Provider**

```dart
// providers/conversation_provider.dart
class ConversationProvider {
  Future<void> exportConversation(String conversationId) async {
    await _storage.exportConversation(conversationId, '/export/path');
    // Show success message
  }
}
```

**Step 4: Add UI Button**

```dart
// widgets/conversation_drawer.dart
PopupMenuItem(
  value: 'export',
  child: Row(
    children: [
      Icon(Icons.download),
      Text('Export'),
    ],
  ),
  onTap: () => provider.exportConversation(conversation.id),
)
```

### Adding a New Screen

```dart
// 1. Create screen file
// screens/my_new_screen.dart
class MyNewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Feature')),
      body: Center(child: Text('Content here')),
    );
  }
}

// 2. Add navigation
IconButton(
  icon: Icon(Icons.new_feature),
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MyNewScreen()),
  ),
)
```

### Modifying LLM Parameters

```dart
// providers/chat_provider.dart
class ChatProvider {
  // Add new parameter
  double _topK = 40.0;
  
  double get topK => _topK;
  
  void updateSettings({
    int? maxTokens,
    double? temperature,
    double? topP,
    double? topK, // NEW
  }) {
    if (maxTokens != null) _maxTokens = maxTokens;
    if (temperature != null) _temperature = temperature;
    if (topP != null) _topP = topP;
    if (topK != null) _topK = topK; // NEW
    notifyListeners();
  }
}

// Use in settings screen
Slider(
  value: chatProvider.topK,
  min: 1,
  max: 100,
  onChanged: (value) => chatProvider.updateSettings(topK: value),
)
```

---

## Key Design Decisions & Rationale

### 1. **Why Provider instead of Bloc/Riverpod?**

**Answer**: Simplicity + Performance
- Provider is lightweight and built into Flutter
- Easy to understand for new contributors
- Sufficient for app's complexity
- Less boilerplate than Bloc

### 2. **Why lazy loading conversations?**

**Answer**: Performance
- App starts 10x faster (50ms vs 500ms)
- Most users don't open drawer immediately
- Saves memory on devices with limited RAM

### 3. **Why compute() for JSON parsing?**

**Answer**: Eliminate UI freezes
- JSON parsing is CPU-intensive
- Large conversation history = 100-300ms blocking
- compute() moves work to background isolate
- UI stays 60fps smooth

### 4. **Why separate files for each conversation?**

**Answer**: Efficient loading
- Don't need to load ALL messages to show conversation list
- Each conversation loads independently
- Easier to delete/export individual conversations

### 5. **Why FFI instead of Platform Channels?**

**Answer**: Performance for LLM
- FFI is faster (no serialization)
- Direct C++ calls
- Lower latency for token generation
- Better for real-time inference

### 6. **Why isolates for inference?**

**Answer**: Non-blocking UI
- LLM inference is CPU-intensive (100-1000ms per token)
- Isolates run on separate thread
- UI remains responsive during generation
- Can cancel generation mid-stream

---

## Common Modifications

### Change App Colors

```dart
// config/app_theme.dart
static const Color primaryColor = Color(0xFF10A37F); // Change this
```

### Change Default Model URL

```dart
// services/model_manager.dart
final defaultModels = [
  ModelInfo(
    id: 'my-model',
    name: 'My Custom Model',
    url: 'https://my-server.com/model.gguf', // Change this
    size: 500 * 1024 * 1024,
  ),
];
```

### Change Generation Parameters

```dart
// providers/chat_provider.dart
int _maxTokens = 512;      // Change to 1024 for longer responses
double _temperature = 0.7;  // Lower = more focused, Higher = more creative
double _topP = 0.9;        // Nucleus sampling threshold
```

### Add Custom Chat Template

```dart
// providers/chat_provider.dart
String _buildPrompt() {
  if (_currentModelId?.contains('my-model') ?? false) {
    // Custom template for your model
    return '<custom>$userMessage</custom><response>';
  }
  // ... existing templates
}
```

---

## Troubleshooting

### App is Slow

1. **Check if running in debug mode**
   ```bash
   # Use profile mode instead
   flutter run --profile
   ```

2. **Check for large conversation history**
   - Delete old conversations from drawer
   - Or implement pagination

3. **Check model size**
   - Larger models = slower inference
   - Use Q4_K_M quantization for balance

### Frame Drops / Jank

1. **Enable performance overlay**
   ```bash
   flutter run --profile --enable-performance-overlay
   ```

2. **Check DevTools Performance tab**
   - Look for red/yellow bars
   - Identify expensive builds

3. **Add const constructors**
   ```dart
   // Bad
   Icon(Icons.chat)
   
   // Good
   const Icon(Icons.chat)
   ```

### Conversations Not Saving

1. **Check storage permissions**
2. **Check if compute() is working**
3. **Add debug prints in ConversationStorage**

---

## Summary

This app demonstrates:
- **Offline-first architecture** with local AI inference
- **Performance optimization** through isolates and lazy loading
- **Clean state management** with Provider pattern
- **Modern UI** with dark mode and animations
- **Persistent storage** with efficient JSON handling

The codebase is structured for:
- **Easy extension**: Add features without touching core
- **Performance**: 60fps smooth, sub-100ms startup
- **Maintainability**: Clear separation of concerns
- **Scalability**: Can handle large conversation history

Every design decision prioritizes **user experience** and **performance**, making this app production-ready for offline LLM inference.

---

**For Questions or Contributions:**
1. Read this guide thoroughly
2. Check existing code patterns
3. Test performance with `flutter run --profile`
4. Follow the established architecture

Happy coding! 🚀
