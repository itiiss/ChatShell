import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/screen/chat.dart';

void main() => runApp(const GetMaterialApp(home: Home()));

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(context) {
    return ChatPage();
  }
}
