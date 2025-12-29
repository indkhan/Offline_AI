// chat_screen.dart
// Main chat interface with ChatGPT-style design
// Features: message bubbles, streaming text, stop button, auto-scroll

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/conversation_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/conversation_drawer.dart';
import 'model_selection_screen.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _autoScroll = true;
  bool _wasGenerating = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Rebuild send button state when text changes
    _textController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Disable auto-scroll if user scrolls up
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      _autoScroll = (maxScroll - currentScroll) < 100;
    }
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage(ChatProvider chatProvider) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    _textController.clear();
    chatProvider.sendMessage(text);
    _autoScroll = true;
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, ConversationProvider>(
      builder: (context, chatProvider, conversationProvider, child) {
        // Auto-dismiss keyboard when AI starts generating
        if (chatProvider.isGenerating && !_wasGenerating) {
          _focusNode.unfocus();
        }
        _wasGenerating = chatProvider.isGenerating;
        
        // Auto-scroll when generating
        if (chatProvider.isGenerating) {
          _scrollToBottom();
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: _buildAppBar(context, chatProvider, conversationProvider),
          drawer: const ConversationDrawer(),
          body: Column(
            children: [
              // Error banner
              if (chatProvider.error != null)
                _buildErrorBanner(context, chatProvider),
              
              // Chat messages
              Expanded(
                child: chatProvider.messages.isEmpty
                    ? _buildEmptyState(context, chatProvider)
                    : _buildMessageList(context, chatProvider),
              ),
              
              // Input area
              _buildInputArea(context, chatProvider),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ChatProvider chatProvider,
    ConversationProvider conversationProvider,
  ) {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Chat History',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conversationProvider.activeConversation?.title ?? 'New Chat',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            chatProvider.hasModel
                ? chatProvider.currentModelId ?? 'No model'
                : 'No model loaded',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      actions: [
        // Clear chat button
        if (chatProvider.messages.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear chat',
            onPressed: () => _showClearChatDialog(context, chatProvider),
          ),
        // Model selection
        IconButton(
          icon: const Icon(Icons.smart_toy_outlined),
          tooltip: 'Models',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ModelSelectionScreen()),
          ),
        ),
        // Settings
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, ChatProvider chatProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              chatProvider.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: 20,
            ),
            onPressed: chatProvider.clearError,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ChatProvider chatProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              chatProvider.hasModel
                  ? 'Start a conversation'
                  : 'No model loaded',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              chatProvider.hasModel
                  ? 'Type a message below to begin chatting with the AI'
                  : 'Download and select a model to start chatting',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            if (!chatProvider.hasModel) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ModelSelectionScreen()),
                ),
                icon: const Icon(Icons.download),
                label: const Text('Get Models'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, ChatProvider chatProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chatProvider.messages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.messages[index];
        return ChatBubble(
          message: message,
          isStreaming: message.isStreaming && chatProvider.isGenerating,
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context, ChatProvider chatProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ChatInput(
                  controller: _textController,
                  focusNode: _focusNode,
                  enabled: chatProvider.hasModel,
                  onSubmitted: (_) => _sendMessage(chatProvider),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              _buildSendButton(context, chatProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context, ChatProvider chatProvider) {
    if (chatProvider.isGenerating) {
      // Stop button when generating
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.stop),
          color: Theme.of(context).colorScheme.onError,
          onPressed: chatProvider.stopGeneration,
          tooltip: 'Stop generating',
        ),
      );
    }

    // Send button
    final canSend = chatProvider.hasModel && _textController.text.trim().isNotEmpty;
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: canSend
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_upward),
        color: canSend
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        onPressed: canSend ? () => _sendMessage(chatProvider) : null,
        tooltip: 'Send message',
      ),
    );
  }

  void _showClearChatDialog(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text('This will delete all messages in this conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              chatProvider.clearChat();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
