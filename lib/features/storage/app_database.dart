import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../chat/domain/chat_message_entity.dart';
import '../model_manager/domain/model_info.dart';

class AppDatabase {
  AppDatabase(this.basePath);

  final String basePath;
  Database? _db;

  Future<void> open() async {
    _db ??= await openDatabase(
      path.join(basePath, 'offline_ai.db'),
      version: 2,
      onCreate: (db, _) async {
        await _ensureSchema(db);
      },
      onUpgrade: (db, _, __) async => _ensureSchema(db),
      onOpen: (db) async => _ensureSchema(db),
    );
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        title TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS model_installs (
        model_id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        size_bytes INTEGER NOT NULL,
        installed_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _ensureLegacyColumns(db);
  }

  Future<void> _ensureLegacyColumns(Database db) async {
    final messageColumns = await db.rawQuery("PRAGMA table_info(messages)");
    final hasConversationId = messageColumns.any(
      (row) => row['name'] == 'conversation_id',
    );
    if (!hasConversationId) {
      await db.execute(
        "ALTER TABLE messages ADD COLUMN conversation_id TEXT NOT NULL DEFAULT 'default'",
      );
    }

    final conversationColumns = await db.rawQuery(
      "PRAGMA table_info(conversations)",
    );
    final hasUpdatedAt = conversationColumns.any(
      (row) => row['name'] == 'updated_at',
    );
    if (!hasUpdatedAt) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.execute(
        "ALTER TABLE conversations ADD COLUMN updated_at INTEGER NOT NULL DEFAULT $now",
      );
    }
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('Database is not opened.');
    }
    return db;
  }

  Future<String> getOrCreateDefaultConversation() async {
    const id = 'default';
    final existing = await _database.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (existing.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _database.insert('conversations', {
        'id': id,
        'title': 'Default Chat',
        'created_at': now,
        'updated_at': now,
      });
    }

    return id;
  }

  Future<void> insertMessage({
    required String conversationId,
    required String messageId,
    required String role,
    required String content,
    required DateTime createdAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.insert('messages', {
      'id': messageId,
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'created_at': createdAt.millisecondsSinceEpoch,
    });
    await _database.update(
      'conversations',
      {'updated_at': now},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<List<ChatMessageEntity>> readMessages(String conversationId) async {
    final rows = await _database.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );

    return rows
        .map(
          (row) => ChatMessageEntity(
            id: row['id'] as String,
            role: row['role'] as String,
            content: row['content'] as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row['created_at'] as int,
            ),
          ),
        )
        .toList();
  }

  Future<void> clearConversation(String conversationId) async {
    await _database.delete(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> removeLastAssistantMessage(String conversationId) async {
    final rows = await _database.query(
      'messages',
      where: 'conversation_id = ? AND role = ?',
      whereArgs: [conversationId, 'assistant'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return;
    }
    await _database.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [rows.first['id']],
    );
  }

  Future<void> upsertInstalledModel({
    required String modelId,
    required String filePath,
    required int sizeBytes,
  }) async {
    await _database.insert('model_installs', {
      'model_id': modelId,
      'path': filePath,
      'size_bytes': sizeBytes,
      'installed_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<ModelId, String>> readInstalledModels() async {
    final rows = await _database.query('model_installs');
    final output = <ModelId, String>{};
    for (final row in rows) {
      final modelId = ModelId.values.firstWhere(
        (value) => value.name == row['model_id'],
        orElse: () => ModelId.qwen,
      );
      output[modelId] = row['path'] as String;
    }
    return output;
  }

  Future<void> removeInstalledModel(String modelId) async {
    await _database.delete(
      'model_installs',
      where: 'model_id = ?',
      whereArgs: [modelId],
    );
  }

  Future<void> upsertSetting(String key, String value) async {
    await _database.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> readSetting(String key) async {
    final rows = await _database.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String;
  }
}
