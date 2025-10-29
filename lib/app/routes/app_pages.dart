import 'package:get/get.dart';
import '../modules/chat/views/chat_screen.dart';
import '../modules/chat/controllers/chat_controller.dart';

class AppPages {
  static const initial = '/chat';

  static final routes = [
    GetPage(
      name: '/chat',
      page: () => const ChatScreen(),
      binding: BindingsBuilder(() {
        Get.put(ChatController());
      }),
    ),
  ];
}
