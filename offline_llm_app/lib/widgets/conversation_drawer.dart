// conversation_drawer.dart
// Sidebar drawer for displaying conversation history

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conversation_provider.dart';
import '../models/conversation.dart';

class ConversationDrawer extends StatelessWidget {
  const ConversationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          _buildSearchBar(context),
          Expanded(
            child: _buildConversationList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Consumer<ConversationProvider>(
      builder: (context, provider, child) {
        // Use a stateful wrapper for the text controller
        return _SearchField(provider: provider);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Chat History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Chat',
            onPressed: () {
              final provider = context.read<ConversationProvider>();
              provider.createNewConversation();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(BuildContext context) {
    return Consumer<ConversationProvider>(
      builder: (context, provider, child) {
        // Trigger lazy loading when drawer is built
        provider.ensureConversationsLoaded();
        
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final displayList = provider.displayedConversations;

        if (displayList.isEmpty && provider.searchQuery.isNotEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No conversations found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        if (displayList.isEmpty) {
          return const Center(
            child: Text(
              'No conversations yet',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: displayList.length,
          itemBuilder: (context, index) {
            final conversation = displayList[index];
            final isActive = provider.activeConversation?.id == conversation.id;
            return _buildConversationTile(
              context,
              conversation,
              isActive,
              provider,
            );
          },
        );
      },
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    bool isActive,
    ConversationProvider provider,
  ) {
    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Conversation'),
            content: const Text('Are you sure you want to delete this conversation?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        provider.deleteConversation(conversation.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation deleted')),
        );
      },
      child: ListTile(
        selected: isActive,
        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
        leading: Icon(
          Icons.chat_bubble_outline,
          color: isActive ? Theme.of(context).primaryColor : null,
        ),
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          _formatTimestamp(conversation.updatedAt),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'rename') {
              _showRenameDialog(context, conversation, provider);
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Conversation'),
                  content: const Text('Are you sure you want to delete this conversation?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                provider.deleteConversation(conversation.id);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Rename'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          provider.switchConversation(conversation.id);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    Conversation conversation,
    ConversationProvider provider,
  ) {
    final controller = TextEditingController(text: conversation.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              provider.renameConversation(conversation.id, value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                provider.renameConversation(conversation.id, newTitle);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}

// Stateful search field widget with text controller
class _SearchField extends StatefulWidget {
  final ConversationProvider provider;
  
  const _SearchField({required this.provider});
  
  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _controller,
        onChanged: (query) => widget.provider.searchConversations(query),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: Icon(
            widget.provider.isSearching 
                ? Icons.hourglass_empty 
                : Icons.search,
            size: 20,
          ),
          suffixIcon: widget.provider.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _controller.clear();
                    widget.provider.clearSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
