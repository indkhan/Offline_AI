class ChatMessage {
  ChatMessage({required this.role, required this.content});

  final ChatRole role;
  String content;

  Map<String, dynamic> toJson() => {
        "role": role.name,
        "content": content,
      };

  static ChatMessage fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: ChatRole.values.firstWhere(
        (r) => r.name == json["role"],
        orElse: () => ChatRole.user,
      ),
      content: json["content"] as String? ?? "",
    );
  }
}

enum ChatRole { user, assistant, system }
