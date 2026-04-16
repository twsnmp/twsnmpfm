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

  test('Settings save and load all fields', () async {
    SharedPreferences.setMockInitialValues({
      'count': 10,
      'ttl': 128,
      'timeout': 5,
      'retry': 3,
      'interval': 10,
      'mibName': 'interfaces',
      'showAllPort': true,
      'themeMode': 2, // Dark
    });
    final settings = Settings();
    await Future.delayed(Duration.zero);
    
    expect(settings.count, 10);
    expect(settings.ttl, 128);
    expect(settings.timeout, 5);
    expect(settings.retry, 3);
    expect(settings.interval, 10);
    expect(settings.mibName, 'interfaces');
    expect(settings.showAllPort, true);
    expect(settings.themeMode, ThemeMode.dark);

    settings.count = 20;
    settings.themeMode = ThemeMode.system;
    await settings.save();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('count'), 20);
    expect(prefs.getInt('themeMode'), 0);
  });

  test('Settings ThemeMode mapping', () async {
    SharedPreferences.setMockInitialValues({'themeMode': 1}); // Light
    var settings = Settings();
    await Future.delayed(Duration.zero);
    expect(settings.themeMode, ThemeMode.light);

    SharedPreferences.setMockInitialValues({'themeMode': 2}); // Dark
    settings = Settings();
    await Future.delayed(Duration.zero);
    expect(settings.themeMode, ThemeMode.dark);

    SharedPreferences.setMockInitialValues({'themeMode': 0}); // System
    settings = Settings();
    await Future.delayed(Duration.zero);
    expect(settings.themeMode, ThemeMode.system);
  });
}
