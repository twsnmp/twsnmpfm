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
  String _dnsTarget = "";
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

  String _macAddress = "";
  Map<String, String> _macToVendorMap = {};

  Map<int, String> tcpPortNameMap = {};
  Map<int, String> udpPortNameMap = {};
  String _portNumber = "25";
  String _portProt = "tcp";

  MIBDB? _mibdb;

  final List<DataRow> _results = [];

  _SearchState() {
    _loadMIBDB();
    _loadPortNameMap();
    _loadMacToVendorMap();
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

  void _loadMacToVendorMap() async {
    final svcfile = await rootBundle.loadString('assets/conf/mac-vendors-export.csv');
    final list = svcfile.split("\n");
    for (var i = 0; i < list.length; i++) {
      var l = list[i].trim();
      if (l.length < 4 || l.startsWith("Mac")) {
        continue;
      }
      final f = l.split(",");
      if (l.length < 2) {
        continue;
      }
      final pre = f[0];
      final vendor = f[1].replaceAll('"', '');
      _macToVendorMap[pre] = vendor;
    }
  }

  SingleChildScrollView _dnsView() => SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                initialValue: _dnsTarget,
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
                    _dnsTarget = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.search), labelText: loc?.ipOrHost ?? "IP or Host", hintText: loc?.ipOrHost ?? ""),
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
                    columns: [
                      DataColumn(
                        label: Text(loc!.key),
                      ),
                      DataColumn(
                        label: Text(loc!.value),
                      ),
                    ],
                    rows: _results,
                  )),
            ],
          ),
        ),
      );

  SingleChildScrollView _macToVendorView() => SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                initialValue: _macAddress,
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
                    _macAddress = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.search), labelText: loc?.macAddress ?? "MAC Address", hintText: loc?.macAddress ?? ""),
              ),
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
                    columns: [
                      DataColumn(
                        label: Text(loc!.vendorCode),
                      ),
                      DataColumn(
                        label: Text(loc!.vendorName),
                      ),
                    ],
                    rows: _results,
                  )),
            ],
          ),
        ),
      );

  SingleChildScrollView _portView() => SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                initialValue: _portNumber,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc!.requiredError;
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _portNumber = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.numbers), labelText: loc?.port ?? "Port", hintText: loc?.port ?? ""),
              ),
              Row(
                children: [
                  const Expanded(child: Text("TCP/UDP")),
                  DropdownButton<String>(
                      value: _portProt,
                      items: const [
                        DropdownMenuItem(value: "tcp", child: Text("TCP")),
                        DropdownMenuItem(value: "udp", child: Text("UDP")),
                      ],
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _portProt = value;
                        });
                      }),
                ],
              ),
              Text(
                _errorMsg,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
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
                    columns: [
                      DataColumn(
                        label: Text(loc!.key),
                      ),
                      DataColumn(
                        label: Text(loc!.value),
                      ),
                    ],
                    rows: _results,
                  )),
            ],
          ),
        ),
      );

  SingleChildScrollView _mibTreeView() => SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[],
          ),
        ),
      );

  void _dnsSearch() async {
    setState(() {
      _process = true;
      _results.length = 0;
      _errorMsg = "";
    });
    try {
      var ip = InternetAddress.tryParse(_dnsTarget);
      if (ip == null) {
        var ips = await InternetAddress.lookup(_dnsTarget);
        for (var ip in ips) {
          setState(() {
            _results.add(DataRow(cells: [DataCell(Text("Local DNS ${ip.type.name}")), DataCell(Text(ip.address))]));
          });
        }
        var rs = await DnsUtils.lookupRecord(_dnsTarget, DnsUtils.intToRRecordType(_rrType));
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
        var rs = await DnsUtils.reverseDns(_dnsTarget);
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

  void _macToVendorSearch() {
    var a = _macAddress.split(":");
    while (a.length > 3) {
      a.removeLast();
    }
    final k = a.join(":").toUpperCase();
    final v = _macToVendorMap[k] ?? "Unknown";
    setState(() {
      _results.add(DataRow(cells: [DataCell(Text(k)), DataCell(Text(v))]));
    });
  }

  void _portSearch() {
    final port = int.parse(_portNumber);
    if (_portProt == "tcp") {
      final k = "TCP:$port";
      final v = tcpPortNameMap[port] ?? "Unknown";
      setState(() {
        _results.add(DataRow(cells: [DataCell(Text(k)), DataCell(Text(v))]));
      });
    } else {
      final k = "UDP:$port";
      final v = udpPortNameMap[port] ?? "Unknown";
      setState(() {
        _results.add(DataRow(cells: [DataCell(Text(k)), DataCell(Text(v))]));
      });
    }
  }

  void _mibSearch() {}

  void _search() {
    if (_process) {
      return;
    }
    final index = _tabController?.index ?? 0;
    switch (index) {
      case 0:
        _dnsSearch();
        break;
      case 1:
        _macToVendorSearch();
        break;
      case 2:
        _portSearch();
        break;
      case 3:
        _mibSearch();
        break;
    }
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
          onTap: (v) {
            setState(() {
              _errorMsg = "";
              _results.length = 0;
            });
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _dnsView(),
          _macToVendorView(),
          _portView(),
          _mibTreeView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _search();
        },
        child: _process ? const Icon(Icons.stop, color: Colors.red) : const Icon(Icons.play_circle),
      ),
    ));
  }
}
