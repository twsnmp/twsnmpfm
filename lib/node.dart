import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';

class Node {
  String name;
  String ip;
  String snmpMode;
  String community;
  String user;
  String password;
  String icon;

  Node({
    this.name = '',
    this.ip = '',
    this.snmpMode = '',
    this.community = '',
    this.user = '',
    this.password = '',
    this.icon = '',
  });

  Map toMap() => {
        'name': name,
        'ip': ip,
        'snmpMode': snmpMode,
        'community': community,
        'user': user,
        'password': password,
        'icon': icon,
      };

  Node.fromMap(Map map)
      : name = map['name'],
        ip = map['ip'],
        snmpMode = map['snmpMode'],
        community = map['community'],
        user = map['user'],
        password = map['password'],
        icon = map['icon'];
}

final countViewModel = ChangeNotifierProvider((_) => Nodes());

class Nodes with ChangeNotifier {
  List<Node> nodes = [];

  Nodes() {
    load();
  }

  bool add(Node n) {
    for (var i = 0; i < nodes.length; i++) {
      if (n.ip == nodes[i].ip) {
        return false;
      }
    }
    nodes.add(n);
    return true;
  }

  bool update(int i, Node n) {
    if (i < 0 || i >= nodes.length) {
      return false;
    }
    nodes[i] = n;
    return true;
  }

  bool delete(int i) {
    if (i < 0 || i >= nodes.length) {
      return false;
    }
    nodes.removeAt(i);
    return true;
  }

  Future save() async {
    if (Platform.operatingSystem == 'macos') {
      return;
    }
    List<String> strNodes = nodes.map((n) => json.encode(n.toMap())).toList();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nodes', strNodes);
  }

  Future load() async {
    if (Platform.operatingSystem == 'macos') {
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var result = prefs.getStringList('nodes');
    if (result != null) {
      nodes = result.map((f) => Node.fromMap(json.decode(f))).toList();
    }
  }
}
