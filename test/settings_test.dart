import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twsnmpfm/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Settings initial load with defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = Settings();
    // Allow Future to complete
    await Future.delayed(Duration.zero);
    
    expect(settings.count, 5);
    expect(settings.ttl, 255);
    expect(settings.interval, 5);
    expect(settings.themeMode, ThemeMode.system);
  });

  test('Settings save and load', () async {
    SharedPreferences.setMockInitialValues({
      'count': 10,
      'themeMode': 1,
    });
    final settings = Settings();
    await Future.delayed(Duration.zero);
    
    expect(settings.count, 10);
    expect(settings.themeMode, ThemeMode.light);

    settings.count = 20;
    settings.themeMode = ThemeMode.dark;
    await settings.save();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('count'), 20);
    expect(prefs.getInt('themeMode'), 2);
  });
}
