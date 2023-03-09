import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/chat_bubble.dart';
import 'package:project/chat_service.dart';
import 'package:project/setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MessageType { assistant, user }

class Message {
  final String content;
  final MessageType type;

  Message({
    required this.content,
    required this.type,
  });
}

class ChatController extends GetxController {
  final messages = List<Message>.empty(growable: true).obs;
  final textEditingController = TextEditingController();
  late SharedPreferences prefs;
  late Settings settings;

  @override
  void onInit() async {
    super.onInit();
    prefs = await SharedPreferences.getInstance();
    settings = Settings(prefs: prefs);
  }

  void sendMessage() async {
    final message = textEditingController.text.trim();
    if (message.isNotEmpty) {
      messages.add(Message(content: message, type: MessageType.user));

      try {
        ChatService chatService = ChatService(apiKey: settings.apiKey);

        final response = await chatService.getCompletion(
          message,
          settings.prompt,
          settings.defaultTemperature,
          [],
        );
        final completion = response['choices'][0]['message']['content'];
        messages.add(Message(content: completion, type: MessageType.assistant));
      } catch (e) {
        print('error: $e');
      }
      textEditingController.clear();
    }
  }

  List<Message>? getChatHistory() {
    // final recentHistory = _history?.latestMessages;

    return settings.enableContinuousConversion ? [] : [];
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
                    return controller.messages[index].type == MessageType.user
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
