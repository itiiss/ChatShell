import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/model/chat_history.dart';
import 'package:project/model/setting.dart';
import 'package:project/screen/settting.dart';
import 'package:project/service/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/widget/chat_bubble.dart';

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
  final scrollController = ScrollController();
  final isLoading = false.obs;
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

  int calcMessageHeight(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: 250);

    return textPainter.size.height.toInt() + 10;
  }

  void sendMessage(ScrollController scrollController) async {
    final message = textEditingController.text.trim();
    textEditingController.clear();
    if (message.isNotEmpty) {
      messages.add(Message(content: message, role: MessageType.user.name));
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + calcMessageHeight(message),
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
      history
          .addMessage(Message(content: message, role: MessageType.user.name));

      try {
        ChatService chatService = ChatService(apiKey: settings.apiKey);
        isLoading.value = true;

        messages.add(Message(content: '', role: MessageType.assistant.name));
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );

        final response = await chatService.getCompletion(
          message,
          settings.prompt,
          settings.defaultTemperature,
          getChatHistory(),
        );
        final completion = response['choices'][0]['message']['content'];

        messages.replaceRange(
          messages.length - 1,
          messages.length,
          [Message(content: completion, role: MessageType.assistant.name)],
        );
        isLoading.value = false;

        scrollController.animateTo(
          scrollController.position.maxScrollExtent +
              calcMessageHeight(completion),
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
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
    }
  }

  List<Message>? getChatHistory() {
    final recentHistory = history.recentMessages;
    return settings.enableContinuousConversion ? recentHistory : [];
  }
}

class ChatPage extends StatelessWidget {
  ChatPage({
    super.key,
  });

  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => Setting()),
          ),
        ],
      ),
      body: GetBuilder<ChatController>(
        init: ChatController(),
        builder: (controller) => Column(
          children: [
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: controller.messages.length,
                  controller: scrollController,
                  itemBuilder: (context, index) {
                    return controller.messages[index].role ==
                            MessageType.user.name
                        ? SentMessage(
                            message: controller.messages[index].content,
                            key: Key(controller.messages[index].content),
                          )
                        : ReceivedMessage(
                            message: controller.messages[index].content,
                            key: Key(controller.messages[index].content),
                            isLoading:
                                index == controller.messages.length - 1 &&
                                    controller.isLoading.value,
                          );
                  },
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    child: TextField(
                      readOnly: controller.isLoading.value,
                      controller: controller.textEditingController,
                      decoration: const InputDecoration(
                        hintText: "Enter message",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => IconButton(
                    enableFeedback: !controller.isLoading.value,
                    icon: const Icon(Icons.send),
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                            controller.sendMessage(scrollController);
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
