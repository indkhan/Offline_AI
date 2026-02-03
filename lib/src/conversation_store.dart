import "dart:convert";
import "dart:io";

import "package:path_provider/path_provider.dart";

import "chat_message.dart";

class ConversationStore {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/conversation.json");
  }

  Future<void> save(List<ChatMessage> messages) async {
    final file = await _file();
    final payload = jsonEncode(
      messages.map((m) => m.toJson()).toList(),
    );
    await file.writeAsString(payload);
  }

  Future<List<ChatMessage>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    final list = jsonDecode(raw);
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }
}
