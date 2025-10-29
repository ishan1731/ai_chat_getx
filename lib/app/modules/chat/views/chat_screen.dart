import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ChatController>();
    final textController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Assistant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              await ctrl.clearAll();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: ctrl.messages.length,
              itemBuilder: (context, index) {
                final msg = ctrl.messages[index];
                return MessageBubble(text: msg.message, isUser: msg.isUser);
              },
            )),
          ),
          Obx(() => ctrl.isTyping.value
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('AI is typing... ⌛'),
                )
              : const SizedBox.shrink()),
          _buildInputField(ctrl, textController),
        ],
      ),
    );
  }

  Widget _buildInputField(ChatController ctrl, TextEditingController textCtrl) {
    return SafeArea(
      child: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textCtrl,
                onChanged: (val) => ctrl.userInput.value = val,
                onSubmitted: (_) => ctrl.sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.indigo),
              onPressed: () {
                ctrl.sendMessage();
                textCtrl.clear();
              },
            ),
          ],
        ),
      ),
    );
  }
}
