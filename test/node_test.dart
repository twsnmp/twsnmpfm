import 'package:flutter/material.dart';
import 'package:test/test.dart';
import 'package:twsnmpfm/node.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  
  group('Nodes', () {
    late Nodes nodes;
    
    setUp(() {
      nodes = Nodes();
    });

    test('nodes add duplicate IP', () {
      nodes.add(Node(
          name: "node 1",
          ip: "192.168.1.1",
          community: "public",
          snmpMode: "v2c"));
      expect(
          nodes.add(Node(
              name: "node 2",
              ip: "192.168.1.1",
              community: "public",
              snmpMode: "v2c")),
          false);
      expect(nodes.nodes.length, 1);
    });

    test('nodes update', () {
      nodes.add(Node(
          name: "old node",
          ip: "192.168.1.1",
          community: "public",
          snmpMode: "v2c"));
      expect(
          nodes.update(
              0,
              Node(
                  name: "node 1",
                  ip: "192.168.1.1",
                  community: "public",
                  snmpMode: "v2c")),
          true);
    });

    test('nodes delete', () {
      nodes.add(Node(
          name: "node 1",
          ip: "192.168.1.1",
          community: "public",
          snmpMode: "v2c"));
      expect(nodes.delete(0), true);
      expect(nodes.nodes.length, 0);
    });

    test('nodes get invalid index', () {
      expect(nodes.get(-1).ip, "");
      expect(nodes.get(100).ip, "");
    });
  });

  group('Node Model', () {
    test('Node toMap/fromMap', () {
      final node = Node(
        name: "test node",
        ip: "1.2.3.4",
        snmpMode: "v3",
        community: "comm",
        user: "user",
        password: "pass",
        icon: "server",
        checkPing: true,
        checkCert: true,
        pingState: 0,
        certState: 1,
      );

      final map = node.toMap();
      final node2 = Node.fromMap(map);

      expect(node2.name, node.name);
      expect(node2.ip, node.ip);
      expect(node2.snmpMode, node.snmpMode);
      expect(node2.community, node.community);
      expect(node2.user, node.user);
      expect(node2.password, node.password);
      expect(node2.icon, node.icon);
      expect(node2.checkPing, node.checkPing);
      expect(node2.checkCert, node.checkCert);
      expect(node2.pingState, node.pingState);
      expect(node2.certState, node.certState);
    });

    test('Node getIcon', () {
      expect(Node(icon: 'laptop').getIcon().icon, Icons.laptop);
      expect(Node(icon: 'desktop').getIcon().icon, Icons.desktop_windows);
      expect(Node(icon: 'server').getIcon().icon, Icons.dns);
      expect(Node(icon: 'cloud').getIcon().icon, Icons.cloud);
      expect(Node(icon: 'unknown').getIcon().icon, Icons.lan);
    });
  });

  group('Nodes Persistence', () {
    test('Nodes save and load', () async {
      SharedPreferences.setMockInitialValues({});
      final nodes = Nodes();
      nodes.add(Node(name: "test save", ip: "10.0.0.1"));
      
      // Wait for _save to complete (it's async but add doesn't await it, however we can wait briefly or just assume it's done since it's mock)
      // Actually, shared_preferences mock is synchronous in memory.
      
      final nodes2 = Nodes();
      // We need to wait for _load to complete in constructor. 
      // This is tricky because constructor isn't async.
      // But _load calls notifyListeners().
      
      // Let's manually trigger _load to be sure or just wait.
      await Future.delayed(Duration(milliseconds: 100));
      
      // Nodes constructor calls _load which is async.
      // We might need to expose _load for testing or use a better pattern.
      // For now, let's try to wait.
      
      expect(nodes2.nodes.any((n) => n.ip == "10.0.0.1"), true);
    });
  });
}
