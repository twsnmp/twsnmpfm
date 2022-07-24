import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:dart_snmp/dart_snmp.dart';
import 'dart:async';
import 'package:sprintf/sprintf.dart';
import 'dart:convert';
import "package:p5/p5.dart";
import 'package:twsnmpfm/settings.dart';

class VPanelPage extends StatefulWidget {
  final Node node;
  final Settings settings;
  const VPanelPage({Key? key, required this.node, required this.settings}) : super(key: key);

  @override
  State<VPanelPage> createState() => _VPanelState();
}

class _VPanelState extends State<VPanelPage> {
  double _interval = 10;
  int _timeout = 5;
  int _retry = 1;
  String _errorMsg = '';
  MIBDB? _mibdb;
  Timer? _timer;
  List<Port> _ports = [];
  bool _showAllPort = false;
  List<DataRow> _rows = [];

  _VPanelState() {
    _loadMIBDB();
  }

  @override
  void initState() {
    _interval = widget.settings.interval.toDouble();
    _timeout = widget.settings.timeout;
    _retry = widget.settings.retry;
    _showAllPort = widget.settings.showAllPort;
    super.initState();
  }

  void _loadMIBDB() async {
    final mibfile = await rootBundle.loadString('assets/conf/mib.txt');
    _mibdb = MIBDB(mibfile);
  }

  void _start() {
    _errorMsg = "";
    if (_timer != null) {
      return;
    }
    _getVPanel();
    _timer = Timer.periodic(Duration(seconds: _interval.toInt()), _getVPanelTimer);
  }

  void _getVPanelTimer(Timer t) {
    _getVPanel();
  }

  void _getVPanel() async {
    try {
      _ports = [];
      var t = InternetAddress(widget.node.ip);
      var session = await Snmp.createSession(t, timeout: Duration(seconds: _timeout), retries: _retry);
      final rootOid = _mibdb!.nameToOid("ifType");
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
        if (a.length != 2) {
          continue;
        }
        final index = int.parse(a[1]);
        final port = Port(index);
        port.type = int.parse(m.pdu.varbinds.first.value.toString());
        m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifName.$index")));
        if (m.pdu.error.value == 0) {
          // ifXTable対応
          port.name = m.pdu.varbinds.first.value.toString();
          m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifHighSpeed.$index")));
          if (m.pdu.error.value == 0) {
            port.speed = int.parse(m.pdu.varbinds.first.value.toString());
          }
          m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifHCInOctets.$index")));
          if (m.pdu.error.value == 0) {
            port.inBytes = int.parse(m.pdu.varbinds.first.value.toString());
          }
          for (var n in ["ifHCInMulticastPkts", "ifHCInBroadcastPkts", "ifHCInUcastPkts"]) {
            m = await session.get(Oid.fromString(_mibdb!.nameToOid("$n.$index")));
            if (m.pdu.error.value == 0) {
              port.inPacktes += int.parse(m.pdu.varbinds.first.value.toString());
            }
          }
          m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifHCOutOctets.$index")));
          if (m.pdu.error.value == 0) {
            port.outBytes = int.parse(m.pdu.varbinds.first.value.toString());
          }
          for (var n in ["ifHCOutMulticastPkts", "ifHCOutBroadcastPkts", "ifHCOutUcastPkts"]) {
            m = await session.get(Oid.fromString(_mibdb!.nameToOid("$n.$index")));
            if (m.pdu.error.value == 0) {
              port.outPacktes += int.parse(m.pdu.varbinds.first.value.toString());
            }
          }
        } else {
          m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifDescr.$index")));
          if (m.pdu.error.value == 0) {
            port.name = m.pdu.varbinds.first.value.toString();
          }
          m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifSpeed.$index")));
          if (m.pdu.error.value == 0) {
            port.speed = int.parse(m.pdu.varbinds.first.value.toString());
          }
          m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifInOctets.$index")));
          if (m.pdu.error.value == 0) {
            port.inBytes = int.parse(m.pdu.varbinds.first.value.toString());
          }
          for (var n in ["ifOutUcastPkts", "ifOutNUcastPkts"]) {
            m = await session.get(Oid.fromString(_mibdb!.nameToOid("$n.$index")));
            if (m.pdu.error.value == 0) {
              port.inPacktes += int.parse(m.pdu.varbinds.first.value.toString());
            }
          }
          m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifOutOctets.$index")));
          if (m.pdu.error.value == 0) {
            port.outBytes = int.parse(m.pdu.varbinds.first.value.toString());
          }
          for (var n in ["ifOutUcastPkts", "ifOutNUcastPkts"]) {
            m = await session.get(Oid.fromString(_mibdb!.nameToOid("$n.$index")));
            if (m.pdu.error.value == 0) {
              port.outPacktes += int.parse(m.pdu.varbinds.first.value.toString());
            }
          }
        }
        m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifOutErrors.$index")));
        if (m.pdu.error.value == 0) {
          port.outError = int.parse(m.pdu.varbinds.first.value.toString());
        }
        m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifInErrors.$index")));
        if (m.pdu.error.value == 0) {
          port.inError = int.parse(m.pdu.varbinds.first.value.toString());
        }
        m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifAdminStatus.$index")));
        if (m.pdu.error.value == 0) {
          port.admin = int.parse(m.pdu.varbinds.first.value.toString());
        }
        m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifOperStatus.$index")));
        if (m.pdu.error.value == 0) {
          port.oper = int.parse(m.pdu.varbinds.first.value.toString());
        }
        m = await session.get(Oid.fromString(_mibdb!.nameToOid("ifPhysAddress.$index")));
        if (m.pdu.error.value == 0) {
          port.mac = _getMac(m.pdu.varbinds.first.value.toString());
        }
        port.state = port.admin != 1
            ? "Disable"
            : port.oper == 1
                ? "Up"
                : "Down";
        _ports.add(port);
      }
      session.close();
      setState(() {
        _rows = [];
        for (var p in _ports) {
          if (_showAllPort || p.type != 24) {
            _rows.add(
              DataRow(cells: [
                DataCell(Text(p.index.toString())),
                DataCell(Text(p.name)),
                DataCell(Text(p.state)),
                DataCell(Text(p.speed.toString())),
                DataCell(Text(p.type.toString())),
                DataCell(Text(p.mac)),
                DataCell(Text(p.admin.toString())),
                DataCell(Text(p.oper.toString())),
                DataCell(Text(p.inBytes.toString())),
                DataCell(Text(p.inPacktes.toString())),
                DataCell(Text(p.inError.toString())),
                DataCell(Text(p.outBytes.toString())),
                DataCell(Text(p.outPacktes.toString())),
                DataCell(Text(p.outError.toString())),
              ]),
            );
          }
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

  String _getMac(String s) {
    String r = "";
    if (s.length > 6) {
      for (var c in base64Decode(s)) {
        if (r != "") {
          r += ":";
        }
        r += sprintf("%02x", [c]);
      }
    } else {
      for (var c in s.runes) {
        if (r != "") {
          r += ":";
        }
        r += sprintf("%02x", [c]);
      }
    }
    return r;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final sketch = PanelSketch(_ports, _showAllPort);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${loc.panel} ${widget.node.name}"),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Expanded(child: Text(loc.showAllPort)),
                    Switch(
                      value: _showAllPort,
                      onChanged: (bool value) {
                        setState(() {
                          _showAllPort = value;
                          if (_timer != null) {
                            _getVPanel();
                          }
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text("${loc.interval}(${_interval.toInt()}${loc.sec})")),
                    Slider(
                        label: "${_interval.toInt()}${loc.sec}",
                        value: _interval,
                        min: 5,
                        max: 60,
                        divisions: (60 - 5) ~/ 5,
                        onChanged: (value) => {
                              setState(() {
                                _interval = value;
                              })
                            }),
                  ],
                ),
                Text(_errorMsg, style: const TextStyle(color: Colors.red)),
                Center(
                  child: SizedBox(
                    height: ((_rows.length ~/ 8) * 25) + 45,
                    width: 8 * 25 + 40,
                    child: PWidget(sketch),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 16,
                      ),
                      headingRowHeight: 22,
                      dataTextStyle: const TextStyle(color: Colors.black, fontSize: 14),
                      dataRowHeight: 20,
                      columns: const [
                        DataColumn(label: Text("Index")),
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("State")),
                        DataColumn(label: Text("Speed")),
                        DataColumn(label: Text("Type")),
                        DataColumn(label: Text("MAC")),
                        DataColumn(label: Text("admin")),
                        DataColumn(label: Text("oper")),
                        DataColumn(label: Text("Rx Bytes")),
                        DataColumn(label: Text("Rx Packtes")),
                        DataColumn(label: Text("Rx Errors")),
                        DataColumn(label: Text("Tx Bytes")),
                        DataColumn(label: Text("Tx Packtes")),
                        DataColumn(label: Text("Tx Errors")),
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

class Port {
  int index = 0;
  String state = "";
  String name = "";
  int speed = 0;
  int outPacktes = 0;
  int outBytes = 0;
  int outError = 0;
  int inPacktes = 0;
  int inBytes = 0;
  int inError = 0;
  int type = 0;
  int admin = 0;
  int oper = 0;
  String mac = "";
  Port(this.index);
}

class PanelSketch extends PPainter {
  List<Port> ports = [];
  bool showAllPorts = false;
  PanelSketch(this.ports, this.showAllPorts);
  @override
  void setup() {}

  @override
  void draw() {
    background(color(64, 64, 64, 240));
    int i = 0;
    for (var p in ports) {
      if (!showAllPorts && p.type == 24) {
        continue;
      }
      final int x = (i % 8) * 25 + 20;
      final int y = (i ~/ 8) * 25 + 10;
      switch (p.state) {
        case "Up":
          if (p.speed >= 1000) {
            fill(color(0, 192, 0, 192));
          } else {
            fill(color(0, 128, 192, 192));
          }
          break;
        case "Down":
          fill(color(254, 0, 0, 192));
          break;
        default:
          fill(color(192, 192, 192, 192));
          break;
      }
      strokeWeight(1);
      stroke(color(10, 10, 10, 192));
      rect(x.toDouble(), y.toDouble(), 18, 18);
      i++;
    }
  }
}
