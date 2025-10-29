import 'package:sqflite/sqflite.dart';
import 'chat_database.dart';
import '../models/chat_message_model.dart';

class ChatDao {
  final ChatDatabase _db = ChatDatabase();

  Future<int> insertMessage(ChatMessage msg) async {
    final db = await _db.database;
    return await db.insert('chat_messages', msg.toMap());
  }

  Future<List<ChatMessage>> getAllMessages() async {
    final db = await _db.database;
    final rows = await db.query('chat_messages', orderBy: 'id ASC');
    return rows.map((r) => ChatMessage.fromMap(r)).toList();
  }

  Future<void> clearAll() async {
    final db = await _db.database;
    await db.delete('chat_messages');
  }
}
