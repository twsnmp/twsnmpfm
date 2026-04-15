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

    test('nodes add', () {
      expect(
          nodes.add(Node(
            name: "node 1",
            ip: "192.168.1.1",
            community: "public",
            snmpMode: "v2c",
          )),
          true);
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
    });
  });
}
