import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/screen/settting.dart';

void main() => runApp(const GetMaterialApp(home: Home()));

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Setting(),
    );
  }
}
