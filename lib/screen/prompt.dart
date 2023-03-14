import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/model/prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PromptController extends GetxController {
  final promptList = List<PromptModel>.empty(growable: true).obs;
  final promptNameController = TextEditingController();
  final promptContentController = TextEditingController();

  late SharedPreferences prefs;
  late PromptService promptService;

  @override
  void onInit() async {
    super.onInit();
    prefs = await SharedPreferences.getInstance();
    promptService = PromptService(prefs: prefs);
    promptList.addAll(PromptService.loadPrompt(prefs));
  }

  void showDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Add Prompt"),
        content: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: promptNameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextFormField(
                controller: promptContentController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(labelText: "Content"),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              promptList.add(
                PromptModel(
                  content: promptContentController.text,
                  name: promptNameController.text,
                ),
              );
              promptService.savePrompt(promptList);
              promptNameController.clear();
              promptContentController.clear();
              Get.back();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void removePrompt(String name) {
    promptList.removeWhere((element) => element.name == name);
    promptService.savePrompt(promptList);
  }
}

class Prompt extends StatelessWidget {
  Prompt({Key? key}) : super(key: key);

  final PromptController promptController = Get.put(PromptController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt'),
        actions: [
          IconButton(
            onPressed: () {
              promptController.showDialog();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Expanded(
              //       child: ElevatedButton(
              //         onPressed: () {
              //           promptController.showDialog();
              //         },
              //         child: const Text('Add'),
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 20),
              Obx(
                () => ListView.builder(
                  shrinkWrap: true,
                  itemCount: promptController.promptList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final item = promptController.promptList[index];
                    return Dismissible(
                      key: Key(item.name),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        promptController.removePrompt(item.name);
                      },
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(item.content),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
