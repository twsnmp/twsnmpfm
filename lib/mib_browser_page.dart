import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:dart_snmp/dart_snmp.dart';
import 'package:sprintf/sprintf.dart';
import 'package:twsnmpfm/settings.dart';

class MibBrowserPage extends StatefulWidget {
  final Node node;
  final Settings settings;
  const MibBrowserPage({super.key, required this.node, required this.settings});

  @override
  State<MibBrowserPage> createState() => _MibBrowserState();
}

class _MibBrowserState extends State<MibBrowserPage> {
  final List<DataRow> _rows = [];
  List<DataColumn> _columns = const [
    DataColumn(
      label: Text("Name"),
    ),
    DataColumn(
      label: Text("Value"),
    ),
  ];
  List<String> _mibNames = [];
  String _mibName = '';
  int _timeout = 5;
  int _retry = 1;
  String _errorMsg = '';
  MIBDB? _mibdb;
  bool _progoress = false;
  AppLocalizations? loc;

  _MibBrowserState() {
    _loadMIBDB();
  }
  @override
  void initState() {
    _mibName = widget.settings.mibName;
    _timeout = widget.settings.timeout;
    _retry = widget.settings.retry;
    super.initState();
  }

  void _loadMIBDB() async {
    final mibfile = await rootBundle.loadString('assets/conf/mib.txt');
    _mibdb = MIBDB(mibfile);
    _mibNames = _mibdb!.getAllNames();
  }

  void _startSnmp() {
    _errorMsg = "";
    if (_mibName.endsWith("Table")) {
      _doGetTable();
    } else {
      _doSnmpWalk();
    }
  }

  void _doSnmpWalk() async {
    try {
      _rows.length = 0;
      setState(() {
        _columns = [
          DataColumn(
            label: Text(loc!.mibName),
          ),
          DataColumn(
            label: Text(loc!.mibValue),
          ),
        ];
      });
      var t = InternetAddress(widget.node.ip);
      var session = await Snmp.createSession(t, timeout: Duration(seconds: _timeout), retries: _retry, community: widget.node.community);
      final rootOid = _mibdb!.nameToOid(_mibName);
      var currentOid = rootOid;
      _progoress = true;
      while (_progoress) {
        final oid = Oid.fromString(currentOid);
        final message = await session.getNext(oid);
        currentOid = message.pdu.varbinds.first.oid.identifier!;
        if (currentOid.indexOf(rootOid) != 0) {
          _progoress = false;
          break;
        }
        final vbname = _mibdb?.oidToName(message.pdu.varbinds.first.oid.identifier) ?? "";
        if (vbname == "") {
          continue;
        }
        var vbval = message.pdu.varbinds.first.value.toString();
        if (vbname.startsWith("ifPhysAd")) {
          vbval = strMacToHex(vbval);
        }
        if (message.pdu.varbinds.first.tag == OID) {
          vbval = _mibdb!.oidToName(vbval);
        }
        setState(() {
          _rows.add(
            DataRow(cells: [
              DataCell(Text(vbname)),
              DataCell(Text(vbval)),
            ]),
          );
        });
      }
      session.close();
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
      _progoress = false;
    }
  }

  void _doGetTable() async {
    final List<String> names = [];
    final List<String> indexes = [];
    final List<List<String>> rows = [[]];
    try {
      var t = InternetAddress(widget.node.ip);
      var session = await Snmp.createSession(t, timeout: Duration(seconds: _timeout), retries: _retry, community: widget.node.community);
      final rootOid = _mibdb!.nameToOid(_mibName);
      var currentOid = rootOid;
      _progoress = true;
      while (_progoress) {
        final oid = Oid.fromString(currentOid);
        final message = await session.getNext(oid);
        currentOid = message.pdu.varbinds.first.oid.identifier!;
        if (currentOid.indexOf(rootOid) != 0) {
          _progoress = false;
          break;
        }
        final vbname = _mibdb?.oidToName(message.pdu.varbinds.first.oid.identifier) ?? "";
        if (vbname == "") {
          continue;
        }
        var vbval = message.pdu.varbinds.first.value.toString();
        if (message.pdu.varbinds.first.tag == OID) {
          vbval = _mibdb!.oidToName(vbval);
        }
        if (vbname.startsWith("ifPhysAd")) {
          vbval = strMacToHex(vbval);
        }
        final i = vbname.indexOf(".");
        if (i < 2) {
          continue;
        }
        final base = vbname.substring(0, i);
        final index = vbname.substring(i + 1);
        if (!names.contains(base)) {
          names.add(base);
        }
        if (!indexes.contains(index)) {
          indexes.add(index);
          rows.add([]);
        }
        final r = indexes.indexOf(index);
        rows[r].add(vbval);
      }
      setState(() {
        _columns = [];
        _columns.add(const DataColumn(label: Text("Index")));
        for (var n in names) {
          _columns.add(DataColumn(label: Text(n)));
        }
        _rows.length = 0;
        for (var r = 0; r < indexes.length; r++) {
          final List<DataCell> cells = [];
          cells.add(DataCell(Text(indexes[r])));
          for (var c = 0; c < names.length; c++) {
            cells.add(DataCell(Text(rows[r][c])));
          }
          _rows.add(DataRow(cells: cells));
        }
      });
      session.close();
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
      _progoress = false;
    }
  }

  void _stopSnmp() {
    _progoress = false;
  }

  String strMacToHex(String s) {
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
  Widget build(BuildContext context) {
    bool dark = Theme.of(context).brightness == Brightness.dark;
    loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${loc!.mibBrowser} ${widget.node.name}"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          scrollDirection: Axis.vertical,
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _mibName),
                  optionsBuilder: (value) {
                    if (value.text.isEmpty) {
                      return [];
                    }
                    return _mibNames.where((n) => n.toLowerCase().contains(value.text.toLowerCase()));
                  },
                  onSelected: (value) {
                    setState(() {
                      _mibName = value;
                    });
                  },
                ),
                Text(_errorMsg, style: const TextStyle(color: Colors.red)),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: TextStyle(
                      color: dark ? Colors.white : Colors.blueGrey,
                      fontSize: 14,
                    ),
                    headingRowHeight: 20,
                    dataTextStyle: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 12),
                    dataRowMinHeight: 10,
                    dataRowMaxHeight: 18,
                    columns: _columns,
                    rows: _rows,
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_progoress) {
              _stopSnmp();
            } else {
              _startSnmp();
            }
          },
          child: _progoress ? const Icon(Icons.stop, color: Colors.red) : const Icon(Icons.play_circle),
        ),
      ),
    );
  }
}
