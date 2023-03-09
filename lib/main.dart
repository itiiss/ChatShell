import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project/chat.dart';
import 'package:project/constants.dart';
import 'package:project/setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(GetMaterialApp(home: Home()));

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
  setTemperature(value) => temperature.value = double.tryParse(value) ?? 0;
  setEnableContinuousConversion(value) =>
      enableContinuousConversion.value = value;
  setEnableLocalCache(value) => enableLocalCache.value = value;
}

class Home extends StatelessWidget {
  Home({super.key});

  Widget _buildTextField({
    required void Function(String) onChanged,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
      onChanged: onChanged,
    );
  }

  final SettingController settingController = Get.put(SettingController());

  void _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Settings settings = Settings(prefs: prefs);
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
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Obx(
            () => Column(
              children: [
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'API Key',
                  onChanged: (value) {
                    settingController.setApiKey(value);
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Prompt',
                  onChanged: (value) {
                    settingController.setPrompt(value);
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                    label: 'Temperature',
                    onChanged: (value) {
                      settingController.setTemperature(value);
                    },
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
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
                  title: const Text('Enable Local Cache'),
                  value: settingController.enableLocalCache.value,
                  onChanged: (value) {
                    settingController.setEnableLocalCache(value);
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Get.to(() => const ChatPage());
                  },
                  child: const Text('Chat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
