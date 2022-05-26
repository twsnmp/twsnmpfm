import 'dart:convert';
import 'dart:io';
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
}

final nodesProvider = Provider((_) => Nodes());

class Nodes {
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

  Node get(int i) {
    if (i < 0 || i >= nodes.length) {
      return Node();
    }
    return nodes[i];
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
