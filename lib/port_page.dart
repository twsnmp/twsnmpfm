import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:dart_snmp/dart_snmp.dart';
import 'dart:async';
import 'package:sprintf/sprintf.dart';
import 'package:twsnmpfm/settings.dart';

class PortPage extends StatefulWidget {
  final Node node;
  final Settings settings;
  const PortPage({Key? key, required this.node, required this.settings}) : super(key: key);

  @override
  State<PortPage> createState() => _PortState();
}

class _PortState extends State<PortPage> {
  double _interval = 10;
  int _timeout = 30;
  int _retry = 1;
  String _errorMsg = '';
  MIBDB? _mibdb;
  Timer? _timer;
  List<TcpUdpPort> _ports = [];
  String _selectedProtocol = "tcp";
  List<DataRow> _rows = [];
  Map<int, String> tcpPortNameMap = {};
  Map<int, String> udpPortNameMap = {};
  _PortState() {
    _loadMIBDB();
    _loadPortNameMap();
  }

  @override
  void initState() {
    _interval = widget.settings.interval.toDouble();
    if (_interval < 30) {
      _interval = 30;
    }
    _timeout = widget.settings.timeout;
    _retry = widget.settings.retry;
    super.initState();
  }

  void _loadMIBDB() async {
    final mibfile = await rootBundle.loadString('assets/conf/mib.txt');
    _mibdb = MIBDB(mibfile);
  }

  void _loadPortNameMap() async {
    final svcfile = await rootBundle.loadString('assets/conf/services.txt');
    final list = svcfile.split("\n");
    for (var i = 0; i < list.length; i++) {
      var l = list[i].trim();
      if (l.length < 4 || l.startsWith("#")) {
        continue;
      }
      final f = l.split(RegExp(r'\s+'));
      if (l.length < 2) {
        continue;
      }
      final sn = f[0];
      final a = f[1].split("/");
      if (a.length != 2) {
        continue;
      }
      final p = int.parse(a[0]);
      if (a[1] == "tcp") {
        tcpPortNameMap[p] = sn;
      } else if (a[1] == "udp") {
        udpPortNameMap[p] = sn;
      }
    }
  }

  void _start() {
    _errorMsg = "";
    if (_timer != null) {
      return;
    }
    _getPortList();
    _timer = Timer.periodic(Duration(seconds: _interval.toInt()), _getPortListTimer);
  }

  void _getPortListTimer(Timer t) {
    _getPortList();
  }

  void _getPortList() {
    if (_selectedProtocol == "udp") {
      _getUdpPortList();
    } else {
      _getTcpPortList();
    }
  }

  void _getTcpPortList() async {
    try {
      _ports = [];
      var t = InternetAddress(widget.node.ip);
      var session = await Snmp.createSession(t, timeout: Duration(seconds: _timeout), retries: _retry);
      final rootOid = _mibdb!.nameToOid("tcpListenerProcess");
      var currentOid = rootOid;
      while (true) {
        final oid = Oid.fromString(currentOid);
        var m = await session.getNext(oid);
        if (m.pdu.error.value != 0) {
          break;
        }
        currentOid = m.pdu.varbinds.first.oid.identifier!;
        if (currentOid.indexOf(rootOid) != 0) {
          break;
        }
        final vbname = _mibdb?.oidToName(m.pdu.varbinds.first.oid.identifier) ?? "";
        final a = vbname.split(".");
        if (a.length < 2) {
          continue;
        }
        final p = int.parse(a[a.length - 1]);
        if (p < 1) {
          continue;
        }
        final port = TcpUdpPort(p);
        final pid = int.parse(m.pdu.varbinds.first.value.toString());
        port.process = "$pid";
        if (pid > 0) {
          m = await session.get(Oid.fromString(_mibdb!.nameToOid("hrSWRunName.$pid")));
          if (m.pdu.error.value == 0) {
            port.process = m.pdu.varbinds.first.value.toString();
          }
        }
        if (tcpPortNameMap.containsKey(p)) {
          port.info = tcpPortNameMap[p]!;
        }
        port.address = _getLocalAddr(a);
        _ports.add(port);
      }
      session.close();
      _ports.sort((a, b) => a.port.compareTo(b.port));
      setState(() {
        _rows = [];
        for (var p in _ports) {
          _rows.add(
            DataRow(cells: [
              DataCell(Text(p.port.toString())),
              DataCell(Text(p.address)),
              DataCell(Text(p.process)),
              DataCell(Text(p.info)),
            ]),
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    }
  }

  void _getUdpPortList() async {
    try {
      _ports = [];
      var t = InternetAddress(widget.node.ip);
      var session = await Snmp.createSession(t, timeout: Duration(seconds: _timeout), retries: _retry);
      final rootOid = _mibdb!.nameToOid("udpEndpointProcess");
      var currentOid = rootOid;
      while (true) {
        final oid = Oid.fromString(currentOid);
        var m = await session.getNext(oid);
        if (m.pdu.error.value != 0) {
          break;
        }
        currentOid = m.pdu.varbinds.first.oid.identifier!;
        if (currentOid.indexOf(rootOid) != 0) {
          break;
        }
        final vbname = _mibdb?.oidToName(m.pdu.varbinds.first.oid.identifier) ?? "";
        final a = vbname.split(".");
        if (a.length < 2) {
          continue;
        }
        final lp = int.parse(a[a[1] == "1" ? 7 : 19]);
        if (lp < 1) {
          continue;
        }
        final rp = int.parse(a[a.length - 2]);
        final port = TcpUdpPort(lp);
        final pid = int.parse(m.pdu.varbinds.first.value.toString());
        port.process = "$pid";
        if (pid > 0) {
          m = await session.get(Oid.fromString(_mibdb!.nameToOid("hrSWRunName.$pid")));
          if (m.pdu.error.value == 0) {
            port.process = m.pdu.varbinds.first.value.toString();
          }
        }
        if (rp > 0) {
          final raddr = _getRemoteAddr(a);
          port.info = "-> $raddr:$rp";
          if (udpPortNameMap.containsKey(rp)) {
            port.info += " ${udpPortNameMap[rp]!}";
          }
        } else {
          if (udpPortNameMap.containsKey(lp)) {
            port.info = udpPortNameMap[lp]!;
          }
        }
        port.address = _getLocalAddr(a);
        _ports.add(port);
      }
      session.close();
      _ports.sort((a, b) => a.port.compareTo(b.port));
      setState(() {
        _rows = [];
        for (var p in _ports) {
          _rows.add(
            DataRow(cells: [
              DataCell(Text(p.port.toString())),
              DataCell(Text(p.address)),
              DataCell(Text(p.process)),
              DataCell(Text(p.info)),
            ]),
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    }
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _timer = null;
    });
  }

  String _getLocalAddr(List<String> a) {
    switch (a[1]) {
      case "1":
        // IPv4
        return a.sublist(3, 4 + 3).join(".");
      case "2":
        // IPv6
        final List<String> r = [];
        for (var i = 3; i < 16 + 3; i++) {
          r.add(sprintf("%02x", [int.parse(a[i])]));
        }
        return r.join(":");
    }
    return "";
  }

  String _getRemoteAddr(List<String> a) {
    switch (a[1]) {
      case "1":
        // IPv4
        return a.sublist(10, 4 + 10).join(".");
      case "2":
        // IPv6
        final List<String> r = [];
        for (var i = 22; i < 16 + 22; i++) {
          r.add(sprintf("%02x", [int.parse(a[i])]));
        }
        return r.join(":");
    }
    return "";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool dark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${loc.port} ${widget.node.name}"),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.all(10),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownButton<String>(
                    value: _selectedProtocol,
                    items: const [
                      DropdownMenuItem(value: "tcp", child: Text("TCP")),
                      DropdownMenuItem(value: "udp", child: Text("UDP")),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _selectedProtocol = value ?? "tcp";
                      });
                      if (_timer != null) {
                        _getPortList();
                      }
                    }),
                Row(
                  children: [
                    Expanded(child: Text("${loc.interval}(${_interval.toInt()}${loc.sec})")),
                    Slider(
                        label: "${_interval.toInt()}${loc.sec}",
                        value: _interval,
                        min: 30,
                        max: 120,
                        divisions: (120 - 30) ~/ 5,
                        onChanged: (value) => {
                              setState(() {
                                _interval = value;
                              })
                            }),
                  ],
                ),
                Text(_errorMsg, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle: TextStyle(
                        color: dark ? Colors.white : Colors.blueGrey,
                        fontSize: 16,
                      ),
                      headingRowHeight: 22,
                      dataTextStyle: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 14),
                      dataRowHeight: 20,
                      columns: const [
                        DataColumn(label: Text("Port")),
                        DataColumn(label: Text("Address")),
                        DataColumn(label: Text("Process")),
                        DataColumn(label: Text("Info")),
                      ],
                      rows: _rows,
                    ))
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_timer != null) {
              _stop();
            } else {
              _start();
            }
          },
          child: _timer != null ? const Icon(Icons.stop, color: Colors.red) : const Icon(Icons.play_circle),
        ),
      ),
    );
  }
}

class TcpUdpPort {
  int port = 0;
  String address = "";
  String process = "";
  String info = "";
  TcpUdpPort(this.port);
}
