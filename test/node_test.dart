import 'package:flutter/material.dart';
import 'package:test/test.dart';
import 'package:twsnmpfm/node.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final nodes = Nodes();
  group('Nodes', () {
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
      expect(nodes.delete(0), true);
    });
  });
}
