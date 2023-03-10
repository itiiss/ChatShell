
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/screen/chat.dart';

class ChatService {
  final String apiKey;

  ChatService({required this.apiKey});

  Future<Map<String, dynamic>> getCompletion(
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

    messages.add({"role": "user", "content": content});

    final body = jsonEncode({
      "model": "gpt-3.5-turbo",
      "temperature": temperature,
      "messages": messages,
    });

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    Utf8Decoder utf8decoder = const Utf8Decoder();
    String responseString = utf8decoder.convert(response.bodyBytes);

    if (response.statusCode == 200) {
      return jsonDecode(responseString);
    } else {
      throw Exception('Failed to load response');
    }
  }
}
