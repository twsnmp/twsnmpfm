import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = ChangeNotifierProvider<Settings>((_) => Settings());

class Settings extends ChangeNotifier {
  int count = 5;
  int ttl = 255;
  int timeout = 2;
  int retry = 1;
  int interval = 5;
  String mibName = "system";
  bool showAllPort = false;
  ThemeMode themeMode = ThemeMode.system;

  Settings() {
    _load();
  }

  Future save() async {
    if (Platform.operatingSystem == 'macos') {
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('count', count);
    await prefs.setInt('ttl', ttl);
    await prefs.setInt('timeout', timeout);
    await prefs.setInt('retry', retry);
    await prefs.setInt('interval', interval);
    await prefs.setInt('themeMode', themeMode.index);
    await prefs.setString('mibName', mibName);
    await prefs.setBool('showAllPort', showAllPort);
    notifyListeners();
  }

  Future _load() async {
    if (Platform.operatingSystem == 'macos') {
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    count = prefs.getInt("count") ?? 5;
    ttl = prefs.getInt("ttl") ?? 255;
    timeout = prefs.getInt("timeout") ?? 2;
    retry = prefs.getInt("retry") ?? 1;
    interval = prefs.getInt("interval") ?? 5;
    mibName = prefs.getString("mibName") ?? "system";
    showAllPort = prefs.getBool("showAllPort") ?? false;
    final tm = prefs.getInt("themeMode") ?? 0;
    switch (tm) {
      case 1:
        themeMode = ThemeMode.light;
        break;
      case 2:
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }
    notifyListeners();
  }
}
