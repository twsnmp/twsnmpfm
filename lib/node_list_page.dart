import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/node_edit_page.dart';
import 'package:twsnmpfm/ping_page.dart';

class NodeListPage extends ConsumerWidget {
  const NodeListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(nodesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('TWSNMP For Mobile')),
      body: Scrollbar(
        child: ListView(
          restorationId: 'node_list_view',
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (int i = 0; i < nodes.nodes.length; i++)
              ListTile(
                  leading: nodes.nodes[i].getIcon(),
                  title: Text(nodes.nodes[i].name),
                  subtitle: Text(nodes.nodes[i].ip),
                  trailing: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) =>
                        {nodeMenuAction(value, i, context, ref)},
                    itemBuilder: (context) => <PopupMenuItem<String>>[
                      PopupMenuItem<String>(
                          value: "ping",
                          child: Row(children: const [
                            Icon(Icons.network_ping),
                            Text("Ping"),
                          ])),
                      PopupMenuItem<String>(
                          value: "snmp",
                          child: Row(children: const [
                            Icon(Icons.storage),
                            Text("SNMP"),
                          ])),
                      PopupMenuItem<String>(
                        value: "pannel",
                        child: Row(children: [
                          const Icon(Icons.lan),
                          Text(AppLocalizations.of(context)!.panel),
                        ]),
                      ),
                      PopupMenuItem<String>(
                          value: "traffic",
                          child: Row(children: [
                            const Icon(Icons.show_chart),
                            Text(AppLocalizations.of(context)!.traffic),
                          ])),
                      PopupMenuItem<String>(
                          value: "edit",
                          child: Row(children: [
                            const Icon(Icons.edit),
                            Text(AppLocalizations.of(context)!.edit),
                          ])),
                      PopupMenuItem<String>(
                        value: "delete",
                        child: Row(children: [
                          const Icon(Icons.delete, color: Colors.red),
                          Text(AppLocalizations.of(context)!.delete),
                        ]),
                      ),
                    ],
                  )),
          ],
        ),
        // );
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {editNode(context, ref, -1)},
        child: const Icon(Icons.add),
      ),
    );
  }

  void nodeMenuAction(
      String action, int i, BuildContext context, WidgetRef ref) {
    final nodes = ref.read(nodesProvider);
    switch (action) {
      case "delete":
        nodes.delete(i);
        return;
      case "edit":
        editNode(context, ref, i);
        return;
      case "ping":
        ping(context, ref, i);
        return;
    }
  }

  void editNode(BuildContext context, WidgetRef ref, int i) async {
    final nodes = ref.read(nodesProvider);
    final editNode = i < 0 ? Node(icon: "lan") : nodes.nodes[i];
    final node = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NodeEditPage(node: editNode)),
    );
    if (node == null) {
      return;
    }
    if (i < 0) {
      nodes.add(node);
    } else {
      nodes.update(i, node);
    }
  }

  void ping(BuildContext context, WidgetRef ref, int i) {
    final nodes = ref.read(nodesProvider);
    if (i < 0 || i >= nodes.nodes.length) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PingPage(ip: nodes.nodes[i].ip)),
    );
  }
}
