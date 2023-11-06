import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:twsnmpfm/settings.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:udp/udp.dart';
import 'package:sprintf/sprintf.dart';

class SearchPage extends StatefulWidget {
  final Settings settings;
  const SearchPage({super.key, required this.settings});

  @override
  State<SearchPage> createState() => _SearchState();
}

class _SearchState extends State<SearchPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  AppLocalizations? loc;
  String _errorMsg = '';
  bool _process = false;
  String _stunServer = "";
  final Map<String, String> _stunServerMap = {
    "": "",
    "stun1.l.google.com": "stun1.l.google.com:19302",
    "stun2.l.google.com": "stun2.l.google.com:19302",
    "stun3.l.google.com": "stun3.l.google.com:19302",
    "stun4.l.google.com": "stun4.l.google.com:19302",
  };
  final List<DropdownMenuItem<String>> _stunServerList = [];

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
  final Map<String, String> _macToVendorMap = {};

  final Map<int, String> tcpPortNameMap = {};
  final Map<int, String> udpPortNameMap = {};
  String _portNumber = "25";
  String _portProt = "tcp";

  MIBDB? _mibdb;
  List<String> _mibNames = [];
  TreeNode? _mibTreeRoot;
  final Map<String, TreeNode> _mibTreeMap = {};

  final List<DataRow> _results = [];

  _SearchState() {
    _loadMIBDB();
    _loadPortNameMap();
    _loadMacToVendorMap();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 5);
    _rrTypeMap.forEach((key, value) {
      _rrTypeList.add(DropdownMenuItem(value: key, child: Text(value)));
    });
    _stunServerMap.forEach((key, value) {
      _stunServerList.add(DropdownMenuItem(value: value, child: Text(key)));
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
    if (_mibdb == null) {
      return;
    }
    // Make MIB Tree
    _mibNames = _mibdb!.getAllNames();
    final List<String> oids = [];
    var minLen = "1.3.6.1".length;
    for (var n in _mibNames) {
      var oid = _mibdb!.nameToOid(n);
      if (oid.length < minLen) {
        continue;
      }
      oids.add(oid);
    }
    oids.sort((a, b) {
      final aa = a.split(".");
      final ba = b.split(".");
      for (var i = 0; i < aa.length && i < ba.length; i++) {
        var l = int.parse(aa[i]);
        var m = int.parse(ba[i]);
        if (l == m) {
          continue;
        }
        return l < m ? -1 : 1;
      }
      return aa.length.compareTo(ba.length);
    });
    _addToMibTree("iso.org.dod.internet", "1.3.6.1", "");
    for (var oid in oids) {
      var n = _mibdb!.oidToName(oid);
      if (n == "") {
        continue;
      }
      final oida = oid.split(".");
      if (oida.length < 2) {
        continue;
      }
      oida.removeLast();
      _addToMibTree(n, oid, oida.join("."));
    }
  }

  void _addToMibTree(String name, String oid, String poid) {
    final n = TreeNode(content: Text("$name($oid)"), children: []);
    if (poid == "") {
      _mibTreeRoot = n;
    } else {
      final p = _mibTreeMap[poid];
      if (p == null) {
        return;
      }
      p.children?.add(n);
    }
    _mibTreeMap[oid] = n;
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

  SingleChildScrollView _myIPView(bool dark) => SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                children: [
                  const Expanded(child: Text("STUN Server")),
                  DropdownButton<String>(
                      value: _stunServer,
                      items: _stunServerList,
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _stunServer = value;
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
                    headingTextStyle: TextStyle(
                      color: dark ? Colors.white : Colors.blueGrey,
                      fontSize: 14,
                    ),
                    headingRowHeight: 20,
                    dataTextStyle: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 12),
                    dataRowMinHeight: 10,
                    dataRowMaxHeight: 18,
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

  SingleChildScrollView _dnsView(bool dark) => SingleChildScrollView(
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
                    headingTextStyle: TextStyle(
                      color: dark ? Colors.white : Colors.blueGrey,
                      fontSize: 14,
                    ),
                    headingRowHeight: 20,
                    dataTextStyle: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 12),
                    dataRowMinHeight: 10,
                    dataRowMaxHeight: 18,
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

  SingleChildScrollView _macToVendorView(bool dark) => SingleChildScrollView(
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
                    headingTextStyle: TextStyle(
                      color: dark ? Colors.white : Colors.blueGrey,
                      fontSize: 14,
                    ),
                    headingRowHeight: 20,
                    dataTextStyle: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 12),
                    dataRowMinHeight: 10,
                    dataRowMaxHeight: 18,
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

  SingleChildScrollView _portView(bool dark) => SingleChildScrollView(
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
                    headingTextStyle: TextStyle(
                      color: dark ? Colors.white : Colors.blueGrey,
                      fontSize: 14,
                    ),
                    headingRowHeight: 20,
                    dataTextStyle: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 12),
                    dataRowMinHeight: 10,
                    dataRowMaxHeight: 18,
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

  SingleChildScrollView _mibTreeView() {
    var tv = _mibTreeRoot != null
        ? TreeView(
            nodes: [_mibTreeRoot!],
            indent: 15,
          )
        : TreeView(nodes: const []);
    return SingleChildScrollView(padding: const EdgeInsets.all(10), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: tv));
  }

  void _myIP() async {
    setState(() {
      _process = true;
      _results.length = 0;
      _errorMsg = "";
    });
    try {
      for (var i in await NetworkInterface.list()) {
        for (var addr in i.addresses) {
          if (!addr.isLoopback) {
            setState(() {
              _results.add(DataRow(cells: [DataCell(Text("${i.name}:${addr.type.name}")), DataCell(Text(addr.address))]));
            });
          }
        }
      }
      if (_stunServer != "") {
        var stunIP = "";
        var stunPort = 0;
        var a = _stunServer.split(":");
        if (a.length > 1) {
          var ips = await InternetAddress.lookup(a[0]);
          for (var ip in ips) {
            if (ip.type.name == "IPv4") {
              stunIP = ip.address;
              break;
            }
          }
          stunPort = int.parse(a[1]);
        }
        if (stunIP != "") {
          var strun = await UDP.bind(Endpoint.any());
          strun.asStream(timeout: const Duration(seconds: 5)).listen((datagram) {
            if (datagram != null && datagram.data.length == 32 && datagram.data[0] == 0x01 && datagram.data[1] == 0x01) {
              var ip = sprintf("%d.%d.%d.%d", [datagram.data[28], datagram.data[29], datagram.data[30], datagram.data[31]]);
              setState(() {
                _results.add(DataRow(cells: [const DataCell(Text("STUN IP")), DataCell(Text(ip))]));
              });
            }
            strun.close();
          });
          await strun.send(_makeSTUNPkt(), Endpoint.unicast(InternetAddress(stunIP), port: Port(stunPort)));
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

  List<int> _makeSTUNPkt() {
    final now = DateTime.now();
    List<int> r = [];
    r.add(0x00); // Bind Request
    r.add(0x01);
    r.add(0x00); // Length
    r.add(0x08);
    // TID
    for (var i = 0; i < 16; i++) {
      r.add(i * now.microsecond);
    }
    r.add(0x00); // Attr Type = Change
    r.add(0x03);
    r.add(0x00); // Attr Len =4
    r.add(0x04);
    r.add(0x00); // Attr
    r.add(0x00);
    r.add(0x00);
    r.add(0x00); // No Change
    return r;
  }

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
        _myIP();
        break;
      case 1:
        _dnsSearch();
        break;
      case 2:
        _macToVendorSearch();
        break;
      case 3:
        _portSearch();
        break;
      case 4:
        _mibSearch();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool dark = Theme.of(context).brightness == Brightness.dark;
    loc = AppLocalizations.of(context)!;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(loc!.search),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: Text("My IP", style: TextStyle(fontSize: 12)),
            ),
            Tab(child: Text("DNS", style: TextStyle(fontSize: 12))),
            Tab(child: Text("MAC", style: TextStyle(fontSize: 12))),
            Tab(child: Text("Port", style: TextStyle(fontSize: 12))),
            Tab(child: Text("MIB", style: TextStyle(fontSize: 12))),
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
          _myIPView(dark),
          _dnsView(dark),
          _macToVendorView(dark),
          _portView(dark),
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
