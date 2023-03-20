import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/model/chat_history.dart';
import 'package:project/model/setting.dart';
import 'package:project/screen/prompt.dart';
import 'package:project/screen/settting.dart';
import 'package:project/service/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/widget/chat_bubble.dart';

class ChatController extends GetxController {
  final messages = List<Message>.empty(growable: true).obs;
  var streamBuffer = ''.obs;
  final textEditingController = TextEditingController();
  final StreamController<Message> messageController =
      StreamController<Message>.broadcast();

  StreamSubscription? streamSubscription;

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

    streamSubscription = messageController.stream.listen((data) {
      if (data.isStop) {
        history.addMessage(messages.elementAt(messages.length - 2));
        history.addMessage(messages.last);
      } else {
        streamBuffer.value = streamBuffer.value + data.content;
        messages.last = Message(content: streamBuffer.value, role: data.role);
        scrollToBottom();
      }
    });

    if (settings.enableLocalCache) {
      messages.addAll(ChatHistory.loadMessage(prefs));
    }
  }

  @override
  void dispose() async {
    super.dispose();
    streamSubscription?.cancel();
    messageController.close();
  }

  void sendMessage() async {
    if (settings.apiKey.isEmpty) {
      Get.dialog(
        AlertDialog(
          title: const Text('OpenAI API Key is not configured.'),
          content:
              const Text('Please configure your Key in the Settings page.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Get.back();
                Get.to(() => Setting());
              },
            ),
          ],
        ),
      );
      return;
    }

    streamBuffer.value = '';

    final message = textEditingController.text.trim();
    textEditingController.clear();
    if (message.isNotEmpty) {
      messages.add(Message(content: message, role: MessageType.user.name));
      history
          .addMessage(Message(content: message, role: MessageType.user.name));

      messages.add(
        Message(content: '', role: MessageType.assistant.name),
      );

      try {
        ChatService chatService = ChatService(
            apiKey: settings.apiKey, messageController: messageController);

        await chatService.getCompletion(
          message,
          settings.prompt,
          settings.defaultTemperature,
          getChatHistory(),
        );

        isLoading.value = false;
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

  void scrollToBottom() {
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutSine,
        );
      },
    );
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

  final PromptSelectController dropdownController =
      Get.put(PromptSelectController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(dropdownController.dropdownValue.value.name)),
        leading: IconButton(
          icon: const Icon(Icons.lightbulb_outline),
          onPressed: () => Get.to(() => Prompt()),
        ),
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
                  controller: controller.scrollController,
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
                            isLoading: false,
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
                            controller.sendMessage();
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
