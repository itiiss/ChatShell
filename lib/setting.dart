import 'package:project/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  Settings({required this.prefs});

  final SharedPreferences prefs;

  String get apiKey => prefs.getString(Constants.apiKeyKey) ?? '';

  set apiKey(String value) => prefs.setString(Constants.apiKeyKey, value);

  String get prompt => prefs.getString(Constants.promptKey) ?? '';

  set prompt(String value) => prefs.setString(Constants.promptKey, value);

  double get defaultTemperature =>
      prefs.getDouble(Constants.defaultTemperatureKey) ??
      Constants.defaultTemperature;

  set defaultTemperature(double value) =>
      prefs.setDouble(Constants.defaultTemperatureKey, value);

  bool get enableContinuousConversion =>
      prefs.getBool(Constants.enableContinuousConversionKey) ??
      Constants.enableContinuousConversion;

  set enableContinuousConversion(bool value) => prefs.setBool(
        Constants.enableContinuousConversionKey,
        value,
      );

  bool get enableLocalCache =>
      prefs.getBool(Constants.enableLocalCacheKey) ??
      Constants.enableLocalCache;

  set enableLocalCache(bool value) => prefs.setBool(
        Constants.enableLocalCacheKey,
        value,
      );
}
