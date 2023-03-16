import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/model/prompt.dart';
import 'package:project/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PromptController extends GetxController {
  final promptList = List<PromptModel>.empty(growable: true).obs;
  final expandList = List<RxBool>.empty(growable: true).obs;
  final isExpanded = false.obs;
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
    expandList.addAll(List.generate(promptList.length, (index) => false.obs));
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
              expandList.add(false.obs);
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

  Widget ellipsisContent(PromptModel item, int index) {
    return Obx(
      () => !promptController.expandList[index].value
          ? GestureDetector(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Utils.isOverflow(item.content, 12, 3)
                      ? const Text(
                          'Expand',
                          style: TextStyle(
                            color: Colors.blue,
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
              onTap: () {
                promptController.expandList[index].toggle();
              },
            )
          : GestureDetector(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.content,
                    maxLines: null,
                  ),
                  const Text(
                    'Hide',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              onTap: () {
                promptController.expandList[index].toggle();
              },
            ),
    );
  }

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
                        subtitle: ellipsisContent(item, index),
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
