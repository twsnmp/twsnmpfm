import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/node_edit_page.dart';
import 'package:twsnmpfm/ping_page.dart';
import 'package:twsnmpfm/mib_browser_page.dart';
import 'package:twsnmpfm/traffic_page.dart';
import 'package:twsnmpfm/vpanel_page.dart';
import 'package:twsnmpfm/host_resource_page.dart';
import 'package:twsnmpfm/processes_page.dart';
import 'package:twsnmpfm/port_page.dart';
import 'package:twsnmpfm/cert_page.dart';
import 'package:twsnmpfm/server_test_page.dart';
import 'package:twsnmpfm/settings.dart';
import 'package:twsnmpfm/settings_page.dart';
import 'package:twsnmpfm/search_page.dart';

class NodeListPage extends ConsumerStatefulWidget {
  const NodeListPage({super.key});
  @override
  NodeListState createState() => NodeListState();
}

class NodeListState extends ConsumerState<NodeListPage> {
  @override
  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodesProvider);
    final loc = AppLocalizations.of(context)!;
    const h = 35.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TWSNMP For Mobile'),
        actions: [
          IconButton(
            tooltip: loc.search,
            icon: const Icon(
              Icons.search,
            ),
            onPressed: () {
              search(context, ref);
            },
          ),
          IconButton(
            tooltip: loc.settings,
            icon: const Icon(
              Icons.settings,
            ),
            onPressed: () {
              settings(context, ref);
            },
          ),
        ],
      ),
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
                    onSelected: (value) => {nodeMenuAction(value, i, context, ref)},
                    itemBuilder: (context) => <PopupMenuItem<String>>[
                      const PopupMenuItem<String>(
                          height: h,
                          value: "ping",
                          child: Row(children: [
                            Icon(Icons.network_ping),
                            Text(
                              "Ping",
                              style: TextStyle(fontSize: 14),
                            ),
                          ])),
                      PopupMenuItem<String>(
                          height: h,
                          value: "snmp",
                          child: Row(children: [
                            const Icon(Icons.storage),
                            Text(
                              loc.mibBrowser,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ])),
                      PopupMenuItem<String>(
                        height: h,
                        value: "panel",
                        child: Row(children: [
                          const Icon(Icons.lan),
                          Text(loc.panel),
                        ]),
                      ),
                      PopupMenuItem<String>(
                          height: h,
                          value: "traffic",
                          child: Row(children: [
                            const Icon(Icons.show_chart),
                            Text(
                              loc.traffic,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ])),
                      PopupMenuItem<String>(
                          height: h,
                          value: "hrmib",
                          child: Row(children: [
                            const Icon(Icons.data_usage),
                            Text(
                              loc.hostResource,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ])),
                      PopupMenuItem<String>(
                          height: h,
                          value: "process",
                          child: Row(children: [
                            const Icon(Icons.memory),
                            Text(
                              loc.processes,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ])),
                      PopupMenuItem<String>(
                          height: h,
                          value: "port",
                          child: Row(children: [
                            const Icon(Icons.drag_indicator),
                            Text(
                              loc.port,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ])),
                      PopupMenuItem<String>(
                          height: h,
                          value: "cert",
                          child: Row(children: [
                            const Icon(Icons.security),
                            Text(
                              loc.cert,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ])),
                      PopupMenuItem<String>(
                          height: h,
                          value: "server",
                          child: Row(children: [
                            const Icon(Icons.rule),
                            Text(
                              loc.serverTest,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ])),
                      PopupMenuItem<String>(
                          height: h,
                          value: "edit",
                          child: Row(children: [
                            const Icon(Icons.edit),
                            Text(
                              loc.edit,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ])),
                      PopupMenuItem<String>(
                        height: h,
                        value: "delete",
                        child: Row(children: [
                          const Icon(Icons.delete, color: Colors.red),
                          Text(
                            loc.delete,
                            style: const TextStyle(fontSize: 14),
                          ),
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

  void nodeMenuAction(String action, int i, BuildContext context, WidgetRef ref) {
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
      case "snmp":
        snmp(context, ref, i);
        return;
      case "panel":
        panel(context, ref, i);
        return;
      case "traffic":
        traffic(context, ref, i);
        return;
      case "hrmib":
        hrmib(context, ref, i);
        return;
      case "process":
        process(context, ref, i);
        return;
      case "port":
        port(context, ref, i);
        return;
      case "cert":
        cert(context, ref, i);
        return;
      case "server":
        server(context, ref, i);
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
    final settings = ref.read(settingsProvider);
    final nodes = ref.read(nodesProvider);
    if (i < 0 || i >= nodes.nodes.length) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PingPage(ip: nodes.nodes[i].ip, settings: settings)),
    );
  }

  void snmp(BuildContext context, WidgetRef ref, int i) {
    final settings = ref.read(settingsProvider);
    final nodes = ref.read(nodesProvider);
    if (i < 0 || i >= nodes.nodes.length) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MibBrowserPage(node: nodes.nodes[i], settings: settings)),
    );
  }

  void panel(BuildContext context, WidgetRef ref, int i) {
    final nodes = ref.read(nodesProvider);
    final settings = ref.read(settingsProvider);
    if (i < 0 || i >= nodes.nodes.length) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VPanelPage(node: nodes.nodes[i], settings: settings)),
    );
  }

  void traffic(BuildContext context, WidgetRef ref, int i) {
    final nodes = ref.read(nodesProvider);
    final settings = ref.read(settingsProvider);
    if (i < 0 || i >= nodes.nodes.length) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TrafficPage(node: nodes.nodes[i], settings: settings)),
    );
  }

  void hrmib(BuildContext context, WidgetRef ref, int i) {
    final nodes = ref.read(nodesProvider);
    final settings = ref.read(settingsProvider);
    if (i < 0 || i >= nodes.nodes.length) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HostResourcePage(node: nodes.nodes[i], settings: settings)),
    );
  }

  void process(BuildContext context, WidgetRef ref, int i) {
    final nodes = ref.read(nodesProvider);
    final settings = ref.read(settingsProvider);
    if (i < 0 || i >= nodes.nodes.length) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProcessesPage(node: nodes.nodes[i], settings: settings)),
    );
  }

  void port(BuildContext context, WidgetRef ref, int i) {
    final nodes = ref.read(nodesProvider);
    final settings = ref.read(settingsProvider);
    if (i < 0 || i >= nodes.nodes.length) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PortPage(node: nodes.nodes[i], settings: settings)),
    );
  }

  void cert(BuildContext context, WidgetRef ref, int i) {
    final nodes = ref.read(nodesProvider);
    final settings = ref.read(settingsProvider);
    if (i < 0 || i >= nodes.nodes.length) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CertPage(node: nodes.nodes[i], settings: settings)),
    );
  }

  void server(BuildContext context, WidgetRef ref, int i) {
    final nodes = ref.read(nodesProvider);
    final settings = ref.read(settingsProvider);
    if (i < 0 || i >= nodes.nodes.length) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ServerTestPage(node: nodes.nodes[i], settings: settings)),
    );
  }

  void settings(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final r = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage(settings: settings)),
    );
    if (r == null) {
      return;
    }
    settings.save();
  }

  void search(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage(settings: settings)),
    );
  }
}
