import "package:flutter/material.dart";

import "../app_controller.dart";
import "../chat_message.dart";
import "../model_spec.dart";
import "chat_bubble.dart";

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offline AI Chat"),
        actions: [
          _ModelDropdown(controller: widget.controller),
          IconButton(
            tooltip: "Clear",
            onPressed: widget.controller.clearConversation,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) {
                final messages = widget.controller.messages;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });
                if (messages.isEmpty) {
                  return const Center(
                    child: Text("Say something to start the chat."),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    if (msg.role == ChatRole.system) return const SizedBox();
                    return ChatBubble(message: msg);
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: widget.controller,
            textController: _textController,
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.textController,
  });

  final AppController controller;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Type your message...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Column(
                  children: [
                    IconButton(
                      onPressed: controller.isGenerating
                          ? controller.stopGeneration
                          : () {
                              final text = textController.text;
                              textController.clear();
                              controller.sendMessage(text);
                            },
                      icon: Icon(
                        controller.isGenerating ? Icons.stop : Icons.send,
                      ),
                    ),
                    if (controller.isGenerating)
                      const Text(
                        "Stop",
                        style: TextStyle(fontSize: 12),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelDropdown extends StatelessWidget {
  const _ModelDropdown({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return DropdownButton<ModelId>(
          value: controller.activeModel,
          onChanged: (id) {
            if (id == null) return;
            controller.setActiveModel(id);
          },
          dropdownColor: const Color(0xFF1E1E1E),
          items: kModels
              .where((spec) => controller.getModelStatus(spec.id).isReady)
              .map(
                (spec) => DropdownMenuItem(
                  value: spec.id,
                  child: Text(spec.name),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
