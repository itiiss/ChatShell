import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/chat_bubble.dart';
import 'package:project/chat_service.dart';

enum MessageType { receiver, sender }

const token = '';

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

  final openAI = OpenAI.instance.build(
      token: "token",
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
      isLogger: true);

  void sendMessage() async {
    final message = textEditingController.text.trim();
    if (message.isNotEmpty) {
      messages.add(Message(content: message, type: MessageType.sender));

      ChatService chatService = ChatService(apiKey: token);

      final response =
          await chatService.getCompletion('${_getChatHistory()}\n$message\n');
      final completion = response['choices'][0]['message']['content'];
      messages.add(Message(content: completion, type: MessageType.receiver));

      textEditingController.clear();
    }
  }

  String _getChatHistory() {
    final history = messages
        .where((message) => message.type == MessageType.sender)
        .map((message) => message.content.trim())
        .join('\n');

    return history;
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
                    return controller.messages[index].type == MessageType.sender
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
