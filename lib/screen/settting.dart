import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/constants.dart';
import 'package:project/model/prompt.dart';
import 'package:project/model/setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingController extends GetxController {
  RxString apiKey = "".obs;
  RxString prompt = "".obs;
  RxDouble temperature = Constants.defaultTemperature.obs;
  RxBool enableContinuousConversion = Constants.enableContinuousConversion.obs;
  RxBool enableLocalCache = Constants.enableLocalCache.obs;
  late SharedPreferences prefs;

  @override
  void onInit() async {
    super.onInit();
    prefs = await SharedPreferences.getInstance();
    apiKey.value = prefs.getString(Constants.apiKeyKey) ?? '';
    prompt.value = prefs.getString(Constants.promptKey) ?? '';
    temperature.value = prefs.getDouble(Constants.defaultTemperatureKey) ??
        Constants.defaultTemperature;
    enableContinuousConversion.value =
        prefs.getBool(Constants.enableContinuousConversionKey) ??
            Constants.enableContinuousConversion;
    enableLocalCache.value = prefs.getBool(Constants.enableLocalCacheKey) ??
        Constants.enableLocalCache;
  }

  setApiKey(value) => apiKey.value = value;
  setPrompt(value) => prompt.value = value;
  setTemperature(value) => temperature.value = value;
  setEnableContinuousConversion(value) =>
      enableContinuousConversion.value = value;
  setEnableLocalCache(value) => enableLocalCache.value = value;
}

class PromptSelectController extends GetxController {
  late Rx<PromptModel> dropdownValue = PromptModel(name: '', content: '').obs;
  final promptList = List<PromptModel>.empty(growable: true).obs;
  late SharedPreferences prefs;
  late PromptService promptService;

  @override
  void onInit() async {
    prefs = await SharedPreferences.getInstance();
    promptService = PromptService(prefs: prefs);
    promptList.addAll(PromptService.loadPrompt(prefs));
    dropdownValue.value = promptList.first;
    super.onInit();
  }

  void dropdownValueChanged(PromptModel? newValue) {
    if (newValue == null) {
      return;
    }

    if (promptList.map((element) => element.name).contains(newValue.name)) {
      dropdownValue.value = newValue;
    }
  }
}

class Setting extends StatelessWidget {
  Setting({super.key});

  Widget _buildTextField({
    required void Function(String) onChanged,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
      controller: controller,
      onChanged: onChanged,
    );
  }

  Widget _buildSlider({
    required void Function(double) onChanged,
    required String label,
    required double value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required PromptSelectController controller,
    required void Function(PromptModel) onChanged,
  }) {
    return Obx(
      () => Focus(
        child: DropdownButtonFormField<PromptModel>(
          value: controller.dropdownValue.value,
          onChanged: (val) {
            onChanged(val!);
            controller.dropdownValueChanged(val);
          },
          items: controller.promptList
              .map<DropdownMenuItem<PromptModel>>((PromptModel p) {
            return DropdownMenuItem<PromptModel>(
              value: p,
              child: Text(p.name),
            );
          }).toList(),
          decoration: const InputDecoration(
            labelText: 'Select a prompt',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.blue,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.red,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  final SettingController settingController = Get.put(SettingController());
  final PromptSelectController promptSelectController =
      Get.put(PromptSelectController());

  void _saveSettings() async {
    Settings settings = Settings(prefs: settingController.prefs);
    settings.apiKey = settingController.apiKey.value;
    settings.prompt = settingController.prompt.value;
    settings.defaultTemperature = settingController.temperature.value;
    settings.enableContinuousConversion =
        settingController.enableContinuousConversion.value;
    settings.enableLocalCache = settingController.enableLocalCache.value;
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Obx(
            () => Column(
              children: [
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'API Key',
                  controller: TextEditingController(
                      text: settingController.apiKey.value),
                  onChanged: (value) {
                    settingController.setApiKey(value);
                  },
                ),
                const SizedBox(height: 20),
                _buildDropdownField(
                  controller: promptSelectController,
                  onChanged: (p) {
                    settingController.setPrompt(p.content);
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Prompt',
                  controller: TextEditingController(
                      text: settingController.prompt.value),
                  onChanged: (value) {
                    settingController.setPrompt(value);
                  },
                ),
                const SizedBox(height: 20),
                _buildSlider(
                  label: 'Temperature',
                  value: settingController.temperature.value,
                  onChanged: (value) {
                    settingController.setTemperature(value);
                  },
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: const Text('Enable Continuous Conversion'),
                  value: settingController.enableContinuousConversion.value,
                  onChanged: (value) {
                    settingController.setEnableContinuousConversion(value);
                  },
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text('Enable Local chat history'),
                  value: settingController.enableLocalCache.value,
                  onChanged: (value) {
                    settingController.setEnableLocalCache(value);
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _saveSettings();
                    Get.back();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
