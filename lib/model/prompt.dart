import 'dart:convert';
import 'package:project/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PromptModel {
  final String name;
  final String content;

  PromptModel({
    required this.name,
    required this.content,
  });

  PromptModel.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        content = json['content'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'content': content,
      };
}

class PromptService {
  PromptService({required this.prefs});

  static const promptKey = 'promptKey';
  final SharedPreferences prefs;
  List<PromptModel> promptList = [];

  void savePrompt(List<PromptModel> promptList) {
    final List<Map<String, dynamic>> data =
        promptList.map((prompt) => prompt.toJson()).toList(growable: false);
    final String json = jsonEncode(data);
    prefs.setString(promptKey, json);
  }

  static List<PromptModel> loadPrompt(SharedPreferences prefs) {
    final String? json = prefs.getString(promptKey);
    if (json != null) {
      final List<dynamic> data = jsonDecode(json);
      return data.isEmpty
          ? [Constants.defaultPrompt]
          : data
              .map((prompt) => PromptModel.fromJson(prompt))
              .toList(growable: false);
    } else {
      return [Constants.defaultPrompt];
    }
  }
}
