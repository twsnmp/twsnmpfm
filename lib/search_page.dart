import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:twsnmpfm/settings.dart';
import 'package:basic_utils/basic_utils.dart';

class SearchPage extends StatefulWidget {
  final Settings settings;
  const SearchPage({Key? key, required this.settings}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchState();
}

class _SearchState extends State<SearchPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  AppLocalizations? loc;
  String _errorMsg = '';
  bool _process = false;
  String _target = "";
  MIBDB? _mibdb;
  int _rrType = 1;
  final Map<int, String> _rrTypeMap = {
    1: "A(IPv4)",
    28: "AAAA(IPv6)",
    255: "ANY",
    257: "CAA",
    59: "CDS",
    37: "CERT",
    5: "CNAME",
    39: "DNAME",
    48: "DNSKEY",
    43: "DS",
    13: "HINFO",
    45: "IPSECKEY",
    15: "MX",
    35: "NPTR",
    2: "NS",
    47: "NSEC",
    51: "NSEC3PARAM",
    12: "PTR",
    17: "RP",
    46: "RRSIG",
    6: "SOA",
    99: "SPF",
    33: "SRV",
    44: "SSHFP",
    52: "TLSA",
    16: "TXT",
    11: "WKS",
  };
  final List<DropdownMenuItem<int>> _rrTypeList = [];

  final List<DataRow> _results = [];

  _SearchState() {
    _loadMIBDB();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 4);
    _rrTypeMap.forEach((key, value) {
      _rrTypeList.add(DropdownMenuItem(value: key, child: Text(value)));
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _loadMIBDB() async {
    final mibfile = await rootBundle.loadString('assets/conf/mib.txt');
    _mibdb = MIBDB(mibfile);
  }

  SingleChildScrollView _dnsView() => SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                initialValue: _target,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc!.requiredError;
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _target = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.edit), labelText: loc?.ipOrHost ?? "IP or Host", hintText: loc?.ipOrHost ?? ""),
              ),
              Row(
                children: [
                  Expanded(child: Text(loc?.rrType ?? "DNS Record Type")),
                  DropdownButton<int>(
                      value: _rrType,
                      items: _rrTypeList,
                      onChanged: (int? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _rrType = value;
                        });
                      }),
                ],
              ),
              Text(
                _errorMsg,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
              DataTable(
                headingTextStyle: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 16,
                ),
                headingRowHeight: 22,
                dataTextStyle: const TextStyle(color: Colors.black, fontSize: 14),
                dataRowHeight: 20,
                columns: [
                  DataColumn(
                    label: Text(loc!.key),
                  ),
                  DataColumn(
                    label: Text(loc!.value),
                  ),
                ],
                rows: _results,
              ),
            ],
          ),
        ),
      );

  void _dnsStart() async {
    setState(() {
      _process = true;
      _results.length = 0;
      _errorMsg = "";
    });
    try {
      var ip = InternetAddress.tryParse(_target);
      if (ip == null) {
        var ips = await InternetAddress.lookup(_target);
        for (var ip in ips) {
          setState(() {
            _results.add(DataRow(cells: [DataCell(Text("Local DNS ${ip.type.name}")), DataCell(Text(ip.address))]));
          });
        }
        var rs = await DnsUtils.lookupRecord(_target, DnsUtils.intToRRecordType(_rrType));
        if (rs != null) {
          for (var r in rs) {
            if (r.rType != _rrType) continue;
            final t = _rrTypeMap[r.rType] ?? "Unknown";
            final k = "Google DNS $t";
            final v = r.data;
            setState(() {
              _results.add(DataRow(cells: [DataCell(Text(k)), DataCell(Text(v))]));
            });
          }
        }
      } else {
        final h = await ip.reverse();
        setState(() {
          _results.add(DataRow(cells: [const DataCell(Text("Local DNS Host")), DataCell(Text(h.host))]));
        });
        var rs = await DnsUtils.reverseDns(_target);
        if (rs != null) {
          setState(() {
            for (var r in rs) {
              final t = _rrTypeMap[r.rType] ?? "Unknown";
              final k = "Google DNS $t";
              final v = r.data;
              _results.add(DataRow(cells: [DataCell(Text(k)), DataCell(Text(v))]));
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    } finally {
      setState(() {
        _process = false;
      });
    }
  }

  void _start() {
    final index = _tabController?.index ?? 0;
    switch (index) {
      case 0:
        _dnsStart();
        break;
    }
  }

  void _stop() {
    setState(() {
      _process = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    loc = AppLocalizations.of(context)!;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(loc!.search),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(child: Text("DNS")),
            Tab(child: Text("MAC")),
            Tab(child: Text("Port")),
            Tab(child: Text("MIB")),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _dnsView(),
          _dnsView(),
          _dnsView(),
          _dnsView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_process) {
            _stop();
          } else {
            _start();
          }
        },
        child: _process ? const Icon(Icons.stop, color: Colors.red) : const Icon(Icons.play_circle),
      ),
    ));
  }
}
