import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local/chat_dao.dart';
import '../models/chat_message_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ChatRepository {
  final ChatDao dao = ChatDao();

  // User's real API endpoint:
  final String baseUrl = "https://app.centurionai.io:8001/api/v1/chatdoc/ask";

  /// Sends POST with {"qestion": "<prompt>"} and yields plain-text chunks as they arrive.
  Stream<String> sendMessage(String prompt) async* {
    final request = http.Request('POST', Uri.parse(baseUrl));
    request.headers.addAll({'Content-Type': 'application/json'});
    request.body = jsonEncode({'qestion': prompt});

    final response = await request.send();

    if (response.statusCode == 200) {
      // assuming server sends plain text chunks
      await for (var chunk in response.stream.transform(utf8.decoder)) {
        yield chunk;
      }
    } else {
      throw Exception('Status: ${response.statusCode}');
    }
  }

  Future<void> saveMessageToDb(String message, bool isUser) async {
    final msg = ChatMessage(
      message: message,
      isUser: isUser,
      createdAt: DateTime.now(),
    );
    await dao.insertMessage(msg);
  }

  /// Append Q&A pair to chat_history.txt in app documents directory.
  Future<void> appendToHistoryFile(String question, String answer) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/chat_history.txt');
    final entry = 'Q: ' + question + '\nA: ' + answer + '\n---\n';
    await file.writeAsString(entry, mode: FileMode.append, flush: true);
  }

  Future<List<ChatMessage>> loadHistoryFromDb() => dao.getAllMessages();
}
