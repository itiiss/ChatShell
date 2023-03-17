import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:project/model/chat_history.dart';

class ChatService {
  final String apiKey;
  final StreamController<Message> messageController;

  ChatService({required this.apiKey, required this.messageController});

  Future<String> getCompletion(
    String content,
    String prompt,
    double temperature,
    List<Message>? lastChat,
  ) async {
    final messages = lastChat?.map((message) {
          return {
            "role":
                message.role == MessageType.user.name ? "user" : "assistant",
            "content": message.content,
          };
        }).toList() ??
        [];
    messages.insert(0, {"role": "system", "content": prompt});

    final body = jsonEncode({
      "model": "gpt-3.5-turbo",
      "temperature": temperature,
      "messages": messages,
      "stream": true,
    });

    HttpClient client = HttpClient();

    final request = await client
        .postUrl(Uri.parse('https://api.openai.com/v1/chat/completions'));
    request.headers.contentType = ContentType.json;
    request.headers.set('Authorization', 'Bearer $apiKey');
    request.write(body);
    final response = await request.close();

    if (response.statusCode == HttpStatus.ok) {
      return await handleStream(response);
    } else {
      throw Exception('Failed to load response');
    }
  }

  Future<String> handleStream(HttpClientResponse response) async {
    String lastTruncatedMessage = "";
    Message chatMessage = Message(role: "assistant", content: "");

    await for (var event in response.transform(utf8.decoder)) {
      event = lastTruncatedMessage + event;
      List<String> itemList = event.split("]}");
      lastTruncatedMessage = itemList.last;

      for (var jsonItem in itemList.sublist(0, itemList.length - 1)) {
        jsonItem = jsonItem.replaceAll("data:", "");
        String formatedJson = "$jsonItem]}";
        final decodeEvent = jsonDecode(formatedJson);

        final content = decodeEvent["choices"][0]["delta"]["content"];
        final role = decodeEvent["choices"][0]["delta"]["role"];
        final finishReason = decodeEvent["choices"][0]["finish_reason"];

        if ('stop' == finishReason) {
          chatMessage =
              Message(role: MessageType.assistant.name, content: 'stop');
          messageController.add(chatMessage);
          return "";
        }

        if (role == MessageType.assistant.name) {
          // do something
        } else {
          if (null != content) {
            chatMessage =
                Message(role: MessageType.assistant.name, content: content);
            messageController.add(chatMessage);
          }
        }
      }
    }

    return "";
  }
}
