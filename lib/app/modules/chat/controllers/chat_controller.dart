import 'package:get/get.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/repository/chat_repository.dart';

class ChatController extends GetxController {
  final ChatRepository repo = ChatRepository();

  var messages = <ChatMessage>[].obs;
  var userInput = ''.obs;
  var isTyping = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMessages();
  }

  Future<void> loadMessages() async {
    final history = await repo.loadHistoryFromDb();
    messages.assignAll(history);
  }

  Future<void> sendMessage() async {
    final text = userInput.value.trim();
    if (text.isEmpty) return;

    // add user message locally & DB
    final userMsg = ChatMessage(message: text, isUser: true, createdAt: DateTime.now());
    messages.add(userMsg);
    await repo.saveMessageToDb(text, true);

    userInput.value = '';
    isTyping.value = true;

    String aiResponse = '';
    try {
      await for (var chunk in repo.sendMessage(text)) {
        aiResponse += chunk;
        if (messages.isNotEmpty && !messages.last.isUser) {
          // update last AI message
          messages.last = ChatMessage(message: aiResponse, isUser: false, createdAt: DateTime.now());
        } else {
          messages.add(ChatMessage(message: aiResponse, isUser: false, createdAt: DateTime.now()));
        }
      }

      // once done, save AI response to DB and append to text history file
      await repo.saveMessageToDb(aiResponse, false);
      await repo.appendToHistoryFile(text, aiResponse);

    } catch (e) {
      final err = 'Error: \$e';
      messages.add(ChatMessage(message: err, isUser: false, createdAt: DateTime.now()));
    } finally {
      isTyping.value = false;
    }
  }

  Future<void> clearAll() async {
    await repo.dao.clearAll();
    messages.clear();
  }
}
