import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Icon getIcon() {
    switch (icon) {
      case 'laptop':
        return const Icon(Icons.laptop);
      case 'desktop':
        return const Icon(Icons.desktop_windows);
      case 'server':
        return const Icon(Icons.dns);
      case 'cloud':
        return const Icon(Icons.cloud);
    }
    return const Icon(Icons.lan);
  }
}

final nodesProvider = ChangeNotifierProvider<Nodes>((_) => Nodes());

class Nodes extends ChangeNotifier {
  List<Node> nodes = [];

  Nodes() {
    _load();
  }

  bool add(Node n) {
    for (var i = 0; i < nodes.length; i++) {
      if (n.ip == nodes[i].ip) {
        return false;
      }
    }
    nodes.add(n);
    notifyListeners();
    _save();
    return true;
  }

  bool update(int i, Node n) {
    if (i < 0 || i >= nodes.length) {
      return false;
    }
    nodes[i] = n;
    notifyListeners();
    _save();
    return true;
  }

  bool delete(int i) {
    if (i < 0 || i >= nodes.length) {
      return false;
    }
    nodes.removeAt(i);
    notifyListeners();
    _save();
    return true;
  }

  Node get(int i) {
    if (i < 0 || i >= nodes.length) {
      return Node();
    }
    return nodes[i];
  }

  _save() async {
    List<String> strNodes = nodes.map((n) => json.encode(n.toMap())).toList();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nodes', strNodes);
  }

  _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var result = prefs.getStringList('nodes');
    if (result != null) {
      nodes = result.map((f) => Node.fromMap(json.decode(f))).toList();
    }
    notifyListeners();
  }
}
