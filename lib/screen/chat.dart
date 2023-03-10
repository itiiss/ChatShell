import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/widget/chat_bubble.dart';
import 'package:project/model/chat_history.dart';
import 'package:project/service/chat_service.dart';
import 'package:project/model/setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MessageType { assistant, user }

class Message {
  final String content;
  final String role;

  Message({
    required this.content,
    required this.role,
  });

  Message.fromJson(Map<String, dynamic> json)
      : role = json['role'],
        content = json['content'];

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class ChatController extends GetxController {
  final messages = List<Message>.empty(growable: true).obs;
  final textEditingController = TextEditingController();
  late SharedPreferences prefs;
  late Settings settings;
  late ChatHistory history;

  @override
  void onInit() async {
    super.onInit();
    prefs = await SharedPreferences.getInstance();
    settings = Settings(prefs: prefs);
    history = ChatHistory(prefs: prefs);
    if (settings.enableLocalCache) {
      messages.addAll(ChatHistory.loadMessage(prefs));
    }
  }

  void sendMessage() async {
    final message = textEditingController.text.trim();
    if (message.isNotEmpty) {
      messages.add(Message(content: message, role: MessageType.user.name));
      history
          .addMessage(Message(content: message, role: MessageType.user.name));

      try {
        ChatService chatService = ChatService(apiKey: settings.apiKey);

        final response = await chatService.getCompletion(
          message,
          settings.prompt,
          settings.defaultTemperature,
          getChatHistory(),
        );
        final completion = response['choices'][0]['message']['content'];
        messages.add(
            Message(content: completion, role: MessageType.assistant.name));
        history.addMessage(
          Message(content: completion, role: MessageType.assistant.name),
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          e.toString(),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
        );
      }
      textEditingController.clear();
    }
  }

  List<Message>? getChatHistory() {
    final recentHistory = history.recentMessages;
    return settings.enableContinuousConversion ? recentHistory : [];
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Page"),
      ),
      body: GetBuilder<ChatController>(
        init: ChatController(),
        builder: (controller) => Column(
          children: [
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    return controller.messages[index].role ==
                            MessageType.user.name
                        ? SentMessageScreen(
                            message: controller.messages[index].content,
                            key: Key(controller.messages[index].content),
                          )
                        : ReceivedMessageScreen(
                            message: controller.messages[index].content,
                            key: Key(controller.messages[index].content),
                          );
                  },
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: controller.textEditingController,
                      decoration: const InputDecoration(
                        hintText: "Enter message",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: controller.sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
