import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:dart_snmp/dart_snmp.dart';

class MibBrowserPage extends StatefulWidget {
  const MibBrowserPage({Key? key, required this.node}) : super(key: key);

  final Node node;

  @override
  State<MibBrowserPage> createState() => _MibBrowserState();
}

class _MibBrowserState extends State<MibBrowserPage> {
  final List<DataRow> _rows = [];
  final List<DataColumn> _columns = const [
    DataColumn(
      label: Text('名前'),
    ),
    DataColumn(
      label: Text('値'),
    ),
  ];
  List<String> _mibNames = [];
  String _mibName = '';
  String _errorMsg = '';
  MIBDB? _mibdb;
  bool _progoress = false;

  _MibBrowserState() {
    _loadMIBDB();
  }

  void _loadMIBDB() async {
    final mibfile = await rootBundle.loadString('assets/conf/mib.txt');
    _mibdb = MIBDB(mibfile);
    _mibNames = _mibdb!.getAllNames();
  }

  void _startSnmp() {
    _doSnmpWalk();
  }

  void _doSnmpWalk() async {
    try {
      _rows.length = 0;
      var t = InternetAddress(widget.node.ip);
      var session = await Snmp.createSession(t);
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
        final vbname =
            _mibdb?.oidToName(message.pdu.varbinds.first.oid.identifier);
        var vbval = message.pdu.varbinds.first.value.toString();
        if (message.pdu.varbinds.first.tag == OID) {
          vbval = _mibdb!.oidToName(vbval);
        }
        setState(() {
          _rows.add(
            DataRow(cells: [
              DataCell(Text(vbname ?? "")),
              DataCell(Text(vbval)),
            ]),
          );
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    }
  }

  void _stopSnmp() {
    _progoress = false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("MIB Browser ${widget.node.name}"),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Autocomplete<String>(
                  optionsBuilder: (value) {
                    if (value.text.isEmpty) {
                      return [];
                    }
                    return _mibNames.where((n) =>
                        n.toLowerCase().contains(value.text.toLowerCase()));
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
                    headingTextStyle: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 16,
                    ),
                    headingRowHeight: 22,
                    dataTextStyle:
                        const TextStyle(color: Colors.black, fontSize: 14),
                    dataRowHeight: 20,
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
          child: _progoress
              ? const Icon(Icons.stop, color: Colors.red)
              : const Icon(Icons.play_circle),
        ),
      ),
    );
  }
}
