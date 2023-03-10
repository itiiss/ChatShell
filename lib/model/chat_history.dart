
import 'dart:convert';

import 'package:project/screen/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatHistory {
  ChatHistory({required this.prefs});

  static const historyKey = 'historyKey';
  final SharedPreferences prefs;
  List<Message> messages = [];

  List<Message> get recentMessages {
    if (messages.length <= 3) {
      return messages;
    }
    return messages.sublist(messages.length - 3);
  }

  void addMessage(Message message) {
    messages.add(message);
    saveMessage();
  }

  void saveMessage() {
    final List<Map<String, dynamic>> data =
        messages.map((message) => message.toJson()).toList(growable: false);
    final String json = jsonEncode(data);
    prefs.setString(historyKey, json);
  }

  static List<Message> loadMessage(SharedPreferences prefs) {
    final String? json = prefs.getString(historyKey);
    if (json != null) {
      final List<dynamic> data = jsonDecode(json);
      return data
          .map((message) => Message.fromJson(message))
          .toList(growable: false);
    } else {
      return [];
    }
  }
}
