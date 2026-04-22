import 'package:flutter/material.dart';
import 'package:twsnmpfm/l10n/app_localizations.dart';
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
import 'dart:io';
import 'dart:async';
import 'package:dart_ping/dart_ping.dart';

class NodeListPage extends ConsumerStatefulWidget {
  const NodeListPage({super.key});
  @override
  NodeListState createState() => NodeListState();
}
class NodeListState extends ConsumerState<NodeListPage> {
  bool _isRunning = false;
  Timer? _timer;
  int _checkTotal = 0;
  int _checkCompleted = 0;
  int _checkErrors = 0;
  String _checkCurrentNodeName = "";
  bool _isCheckFinished = false;
  bool _isCheckCancelled = false;
  String _checkTitle = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  void _startTimer() {
    final settings = ref.read(settingsProvider);
    _timer?.cancel();
    _timer = Timer.periodic(Duration(minutes: settings.interval > 0 ? settings.interval : 5), (timer) async {
      if (!_isRunning) {
        await _runPingChecks(context, ref);
      }
      if (mounted && !_isRunning) {
        await _runCertChecks(context, ref);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodesProvider);
    final loc = AppLocalizations.of(context)!;
    const h = 35.0;
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          identifier: 'main_app_bar_title',
          child: Text(MediaQuery.of(context).size.width > 400
              ? 'TWSNMP For Mobile'
              : 'TWSNMP'),
        ),
        actions: [
          Semantics(
            identifier: 'search_button',
            child: IconButton(
              tooltip: loc.search,
              icon: const Icon(
                Icons.search,
              ),
              onPressed: () {
                search(context, ref);
              },
            ),
          ),
          PopupMenuButton<String>(
            tooltip: loc.start,
            icon: const Icon(Icons.play_circle),
            onSelected: (value) {
              if (_isRunning) return;
              if (value == 'ping') {
                _runPingChecks(context, ref);
              } else if (value == 'cert') {
                _runCertChecks(context, ref);
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: "ping",
                enabled: !_isRunning,
                child: Row(
                  children: [
                    const Icon(Icons.network_ping),
                    const SizedBox(width: 8),
                    Text(loc.runPing, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: "cert",
                enabled: !_isRunning,
                child: Row(
                  children: [
                    const Icon(Icons.security),
                    const SizedBox(width: 8),
                    Text(loc.runCert, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          Semantics(
            identifier: 'settings_button',
            child: IconButton(
              tooltip: loc.settings,
              icon: const Icon(
                Icons.settings,
              ),
              onPressed: () {
                settings(context, ref);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isRunning,
            child: Column(
              children: [
                Expanded(
                  child: Scrollbar(
                child: ListView.builder(
                  restorationId: 'node_list_view',
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: nodes.nodes.length,
                  itemBuilder: (context, i) {
                    final node = nodes.nodes[i];
                    return Semantics(
                      identifier: 'node_list_item_$i',
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: node.getIcon(),
                          title: Text(
                            node.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                node.ip,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (node.pingState != -1)
                                Icon(
                                  node.pingState == 0 ? Icons.check_circle : Icons.error,
                                  size: 16,
                                  color: node.pingState == 0 ? Colors.green : Colors.red,
                                ),
                              if (node.certState != -1)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Icon(
                                    node.certState == 0 ? Icons.verified : 
                                    node.certState == 1 ? Icons.error : 
                                    node.certState == 2 ? Icons.dangerous : Icons.warning,
                                    size: 16,
                                    color: node.certState == 0 ? Colors.green : 
                                           node.certState == 1 ? Colors.red : 
                                           node.certState == 2 ? Colors.red : Colors.amber,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Semantics(
                            container: true,
                            identifier: 'node_menu_button_$i',
                            child: PopupMenuButton<String>(
                              tooltip: 'node_menu_button_$i',
                              padding: EdgeInsets.zero,
                              onSelected: (value) => {nodeMenuAction(value, i, context, ref)},
                              itemBuilder: (context) => <PopupMenuItem<String>>[
                                PopupMenuItem<String>(
                                    height: h,
                                    value: "ping",
                                    child: Semantics(
                                      identifier: 'node_menu_item_ping',
                                      child: const Row(children: [
                                        Icon(Icons.network_ping),
                                        SizedBox(width: 8),
                                        Text("Ping", style: TextStyle(fontSize: 14)),
                                      ]),
                                    )),
                                PopupMenuItem<String>(
                                    height: h,
                                    value: "snmp",
                                    child: Semantics(
                                      identifier: 'node_menu_item_snmp',
                                      child: Row(children: [
                                        const Icon(Icons.storage),
                                        const SizedBox(width: 8),
                                        Text(loc.mibBrowser, style: const TextStyle(fontSize: 14)),
                                      ]),
                                    )),
                                PopupMenuItem<String>(
                                  height: h,
                                  value: "panel",
                                  child: Semantics(
                                    identifier: 'node_menu_item_panel',
                                    child: Row(children: [
                                      const Icon(Icons.lan),
                                      const SizedBox(width: 8),
                                      Text(loc.panel, style: const TextStyle(fontSize: 14)),
                                    ]),
                                  ),
                                ),
                                PopupMenuItem<String>(
                                    height: h,
                                    value: "traffic",
                                    child: Semantics(
                                      identifier: 'node_menu_item_traffic',
                                      child: Row(children: [
                                        const Icon(Icons.show_chart),
                                        const SizedBox(width: 8),
                                        Text(loc.traffic, style: const TextStyle(fontSize: 14)),
                                      ]),
                                    )),
                                PopupMenuItem<String>(
                                    height: h,
                                    value: "hrmib",
                                    child: Semantics(
                                      identifier: 'node_menu_item_hrmib',
                                      child: Row(children: [
                                        const Icon(Icons.data_usage),
                                        const SizedBox(width: 8),
                                        Text(loc.hostResource, style: const TextStyle(fontSize: 14)),
                                      ]),
                                    )),
                                PopupMenuItem<String>(
                                    height: h,
                                    value: "process",
                                    child: Semantics(
                                      identifier: 'node_menu_item_process',
                                      child: Row(children: [
                                        const Icon(Icons.memory),
                                        const SizedBox(width: 8),
                                        Text(loc.processes, style: const TextStyle(fontSize: 14)),
                                      ]),
                                    )),
                                PopupMenuItem<String>(
                                    height: h,
                                    value: "port",
                                    child: Semantics(
                                      identifier: 'node_menu_item_port',
                                      child: Row(children: [
                                        const Icon(Icons.drag_indicator),
                                        const SizedBox(width: 8),
                                        Text(loc.port, style: const TextStyle(fontSize: 14)),
                                      ]),
                                    )),
                                PopupMenuItem<String>(
                                    height: h,
                                    value: "cert",
                                    child: Semantics(
                                      identifier: 'node_menu_item_cert',
                                      child: Row(children: [
                                        const Icon(Icons.security),
                                        const SizedBox(width: 8),
                                        Text(loc.cert, style: const TextStyle(fontSize: 14)),
                                      ]),
                                    )),
                                PopupMenuItem<String>(
                                    height: h,
                                    value: "server",
                                    child: Semantics(
                                      identifier: 'node_menu_item_server',
                                      child: Row(children: [
                                        const Icon(Icons.rule),
                                        const SizedBox(width: 8),
                                        Text(loc.serverTest, style: const TextStyle(fontSize: 14)),
                                      ]),
                                    )),
                                PopupMenuItem<String>(
                                    height: h,
                                    value: "edit",
                                    child: Semantics(
                                      container: true,
                                      identifier: 'node_menu_item_edit',
                                      child: Row(children: [
                                        const Icon(Icons.edit),
                                        const SizedBox(width: 8),
                                        Text(loc.edit, style: const TextStyle(fontSize: 14)),
                                      ]),
                                    )),
                                PopupMenuItem<String>(
                                  height: h,
                                  value: "delete",
                                  child: Semantics(
                                    container: true,
                                    identifier: 'node_menu_item_delete',
                                    child: Row(children: [
                                      Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                      const SizedBox(width: 8),
                                      Text(loc.delete, style: const TextStyle(fontSize: 14)),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
        ),
      ),
      )
     ]
    )
   ),
   if (_isRunning)
     Container(
       color: Colors.black45,
       padding: const EdgeInsets.all(32),
       alignment: Alignment.center,
       child: Card(
         elevation: 8,
         child: Padding(
           padding: const EdgeInsets.all(24),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               Text(_checkTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
               const Divider(),
               const SizedBox(height: 16),
               Text("${loc.checkCompletedCount}: $_checkCompleted / $_checkTotal"),
               const SizedBox(height: 8),
               Text("${loc.checkProblemCount}: $_checkErrors", style: TextStyle(color: _checkErrors > 0 ? Theme.of(context).colorScheme.error : null)),
               const SizedBox(height: 8),
               Text("${loc.checkingNode}: $_checkCurrentNodeName", maxLines: 1, overflow: TextOverflow.ellipsis),
               const SizedBox(height: 24),
               Center(
                 child: _isCheckFinished
                     ? const Icon(Icons.check_circle, color: Colors.green, size: 48)
                     : const CircularProgressIndicator(),
               ),
               if (!_isCheckFinished) ...[
                 const SizedBox(height: 24),
                 OutlinedButton.icon(
                   onPressed: () {
                     setState(() {
                       _isCheckCancelled = true;
                     });
                   },
                   icon: const Icon(Icons.stop),
                   label: Text(loc.stop),
                   style: OutlinedButton.styleFrom(
                     foregroundColor: Theme.of(context).colorScheme.error,
                   ),
                 ),
               ],
             ],
           ),
         ),
       ),
     ),
   ],
  ),
      floatingActionButton: Semantics(
        identifier: 'add_node_fab',
        child: FloatingActionButton(
          onPressed: () => {editNode(context, ref, -1)},
          tooltip: loc.addNode,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _runPingChecks(BuildContext context, WidgetRef ref) async {
    final nodes = ref.read(nodesProvider);
    int total = nodes.nodes.where((n) => n.checkPing).length;
    if (total == 0) return;

    setState(() {
      _isRunning = true;
      _isCheckFinished = false;
      _isCheckCancelled = false;
      _checkTotal = total;
      _checkCompleted = 0;
      _checkErrors = 0;
      _checkCurrentNodeName = "";
      _checkTitle = AppLocalizations.of(context)!.runPing;
    });

    final settings = ref.read(settingsProvider);

    for (int i = 0; i < nodes.nodes.length; i++) {
        if (_isCheckCancelled) break;
        final node = nodes.nodes[i];
        if (node.checkPing) {
            setState(() {
              _checkCurrentNodeName = node.name;
            });
            bool success = false;
            for (int r = 0; r <= settings.retry; r++) {
                try {
                    final ping = Ping(node.ip, count: 1, timeout: settings.timeout);
                    final result = await ping.stream.firstWhere((event) => event.response != null || event.error != null);
                    if (result.response != null && result.error == null) {
                        success = true;
                        break;
                    }
                } catch (e) {
                   // ignore
                }
            }
            node.pingState = success ? 0 : 1;
            nodes.update(i, node); // This notifies listeners
            
            setState(() {
              _checkCompleted++;
              if (!success) _checkErrors++;
            });
        }
    }

    if (mounted) {
      if (_isCheckCancelled) {
        setState(() {
          _isRunning = false;
        });
        return;
      }
      setState(() {
        _isCheckFinished = true;
        _checkCurrentNodeName = AppLocalizations.of(context)!.checkFinished;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  Future<void> _runCertChecks(BuildContext context, WidgetRef ref) async {
    final nodes = ref.read(nodesProvider);
    int total = nodes.nodes.where((n) => n.checkCert).length;
    if (total == 0) return;

    setState(() {
      _isRunning = true;
      _isCheckFinished = false;
      _isCheckCancelled = false;
      _checkTotal = total;
      _checkCompleted = 0;
      _checkErrors = 0;
      _checkCurrentNodeName = "";
      _checkTitle = AppLocalizations.of(context)!.runCert;
    });

    final settings = ref.read(settingsProvider);

    for (int i = 0; i < nodes.nodes.length; i++) {
        if (_isCheckCancelled) break;
        final node = nodes.nodes[i];
        if (node.checkCert) {
            setState(() {
                _checkCurrentNodeName = node.name;
            });
            int state = 1; // Default error/failed
            for (int r = 0; r <= settings.retry; r++) {
                try {
                    bool bad = false;
                    final socket = await SecureSocket.connect(
                        node.ip,
                        443,
                        timeout: Duration(seconds: settings.timeout),
                        onBadCertificate: (cert) {
                            bad = true;
                            return true; // Still accept to check validity limits
                        },
                    );
                    if (socket.peerCertificate != null) {
                        var endValidity = socket.peerCertificate!.endValidity;
                        var now = DateTime.now();
                        if (endValidity.isBefore(now)) {
                            state = 2; // Expired
                        } else if (bad) {
                            state = 1; // Verification Failed
                        } else if (endValidity.difference(now).inDays <= 7) {
                            state = 3; // Expiring within 1 week
                        } else {
                            state = 0; // Normal
                        }
                    }
                    socket.close();
                    break; 
                } catch (e) {
                   // Retry on connect error
                }
            }
            node.certState = state;
            nodes.update(i, node);
            
            setState(() {
                _checkCompleted++;
                if (state != 0) _checkErrors++; 
            });
        }
    }

    if (mounted) {
      if (_isCheckCancelled) {
        setState(() {
          _isRunning = false;
        });
        return;
      }
      setState(() {
        _isCheckFinished = true;
        _checkCurrentNodeName = AppLocalizations.of(context)!.checkFinished;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
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
