import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String apiKey;

  ChatService({required this.apiKey});

  Future<Map<String, dynamic>> getCompletion(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": prompt}
        ]
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load response');
    }
  }
}
