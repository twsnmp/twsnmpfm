import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:dart_snmp/dart_snmp.dart';
import 'package:twsnmpfm/settings.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:twsnmpfm/time_line_chart.dart';

class TrafficPage extends StatefulWidget {
  final Node node;
  final Settings settings;
  const TrafficPage({super.key, required this.node, required this.settings});

  @override
  State<TrafficPage> createState() => _TrafficState();
}

class _TrafficState extends State<TrafficPage> {
  String _selectedTarget = '';
  double _interval = 5;
  int _timeout = 1;
  int _retry = 1;
  AppLocalizations? loc;

  final List<TimeLineSeries> _chartData = [];
  TimeLineSeries? _lastData;
  List<_TrafficTarget> _targetList = [];
  String _errorMsg = '';
  MIBDB? _mibdb;
  Timer? _timer;
  List<DropdownMenuItem<String>> _targetMenuItems = [];
  List<String> _txMIBs = [];
  List<String> _rxMIBs = [];
  List<String> _errorMIBs = [];
  final List<DataRow> _logs = [];
  String _unit = '';

  @override
  void initState() {
    _interval = widget.settings.interval.toDouble();
    _timeout = widget.settings.timeout;
    _retry = widget.settings.retry;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getTragetList();
  }

  Future _loadMIBDB() async {
    final mibfile = await rootBundle.loadString('assets/conf/mib.txt');
    _mibdb = MIBDB(mibfile);
    return true;
  }

  void _start() {
    _errorMsg = "";
    if (_timer != null) {
      return;
    }
    final i = _findTarget();
    if (i < 0) {
      return;
    }
    final index = _targetList[i].index;
    switch (_targetList[i].type) {
      case "tcp":
        _txMIBs = ["tcpOutSegs.0"];
        _rxMIBs = ["tcpInSegs.0"];
        _errorMIBs = ["tcpRetransSegs.0"];
        _unit = "Pkts/Sec";
        break;
      case "udp":
        _txMIBs = ["udpOutDatagrams.0"];
        _rxMIBs = ["udpInDatagrams.0"];
        _errorMIBs = ["udpNoPorts.0", "udpInErrors.0"];
        _unit = "Pkts/Sec";
        break;
      case "ip":
        _txMIBs = ["ipOutRequests.0"];
        _rxMIBs = ["ipInReceives.0"];
        _errorMIBs = ["ipInHdrErrors.0", "ipInAddrErrors.0", "ipInUnknownProtos.0", "ipInDiscards.0", "ipOutDiscards.0", "ipOutNoRoutes.0"];
        _unit = "Pkts/Sec";
        break;
      case "ipfrag":
        _txMIBs = ["ipFragCreates.0"];
        _rxMIBs = ["ipReasmReqds.0"];
        _errorMIBs = ["ipFragFails.0", "ipReasmFails.0"];
        _unit = "Pkts/Sec";
        break;
      case "icmp":
        _txMIBs = ["icmpOutMsgs.0"];
        _rxMIBs = ["icmpInMsgs.0"];
        _errorMIBs = ["icmpInErrors.0", "icmpOutErrors.0"];
        _unit = "Pkts/Sec";
        break;
      case "icmpdu":
        _txMIBs = ["icmpOutDestUnreachs.0"];
        _rxMIBs = ["icmpInDestUnreachs.0"];
        _errorMIBs = [];
        _unit = "Pkts/Sec";
        break;
      case "tcpcon":
        _txMIBs = ["tcpActiveOpens.0"];
        _rxMIBs = ["tcpPassiveOpens.0"];
        _errorMIBs = ["tcpAttemptFails.0", "tcpEstabResets.0"];
        _unit = "Con/Sec";
        break;
      case "snmp":
        _txMIBs = ["snmpOutPkts.0"];
        _rxMIBs = ["snmpInPkts.0"];
        _errorMIBs = ["snmpInBadVersions.0", "snmpInASNParseErrs.0", "snmpInBadCommunityNames.0"];
        _unit = "Pkts/Sec";
        break;
      case "ifPPS":
        _txMIBs = ["ifOutUcastPkts.$index", "ifOutUcastPkts.$index"];
        _rxMIBs = ["ifInUcastPkts.$index", "ifInUcastPkts.$index"];
        _errorMIBs = ["ifInDiscards.$index", "ifInErrors.$index", "ifInUnknownProtos.$index"];
        _unit = "Pkts/Sec";
        break;
      case "ifHCPPS":
        _txMIBs = ["ifHCOutUcastPkts.$index", "ifHCOutMulticastPkts.$index", "ifHCOutBroadcastPkts.$index"];
        _rxMIBs = ["ifHCInUcastPkts.$index", "ifHCInMulticastPkts.$index", "ifHCInBroadcastPkts.$index"];
        _errorMIBs = ["ifInDiscards.$index", "ifInErrors.$index", "ifInUnknownProtos.$index"];
        _unit = "Pkts/Sec";
        break;
      case "ifBPS":
        _txMIBs = ["ifOutOctets.$index"];
        _rxMIBs = ["ifInOctets.$index"];
        _errorMIBs = [];
        _unit = "Bytes/Sec";
        break;
      case "ifHCBPS":
        _txMIBs = ["ifHCOutOctets.$index"];
        _rxMIBs = ["ifHCInOctets.$index"];
        _errorMIBs = [];
        _unit = "Bytes/Sec";
        break;
    }
    setState(() {
      _chartData.length = 0;
      _lastData = null;
      _logs.length = 0;
    });
    _getTraffic();
    _timer = Timer.periodic(Duration(seconds: _interval.toInt()), _getTrafficTimer);
  }

  int _findTarget() {
    for (var i = 0; i < _targetList.length; i++) {
      if (_selectedTarget == _targetList[i].value) {
        return i;
      }
    }
    return -1;
  }

  void _getTrafficTimer(Timer t) async {
    _getTraffic();
  }

  void _getTraffic() async {
    try {
      var t = InternetAddress(widget.node.ip);
      var session = await Snmp.createSession(t, timeout: Duration(seconds: _timeout), retries: _retry);
      double tx = 0.0;
      double rx = 0.0;
      double err = 0.0;
      for (var n in _txMIBs) {
        var m = await session.get(Oid.fromString(_mibdb!.nameToOid(n)));
        if (m.pdu.error.value != 0) {
          debugPrint('get $n  err=${m.pdu.error.value}');
          continue;
        }
        tx += double.parse(m.pdu.varbinds.first.value.toString());
      }
      for (var n in _rxMIBs) {
        var m = await session.get(Oid.fromString(_mibdb!.nameToOid(n)));
        if (m.pdu.error.value != 0) {
          debugPrint('get $n  err=${m.pdu.error.value}');
          continue;
        }
        rx += double.parse(m.pdu.varbinds.first.value.toString());
      }
      for (var n in _errorMIBs) {
        var m = await session.get(Oid.fromString(_mibdb!.nameToOid(n)));
        if (m.pdu.error.value != 0) {
          debugPrint('get $n  err=${m.pdu.error.value}');
          continue;
        }
        err += double.parse(m.pdu.varbinds.first.value.toString());
      }
      debugPrint('tx=$tx rx=$rx err=$err $_txMIBs $_rxMIBs $_errorMIBs');
      final now = DateTime.now();
      session.close();
      if (_lastData == null) {
        _lastData = TimeLineSeries(now.millisecondsSinceEpoch.toDouble(), <double>[tx, rx, err]);
        return;
      }
      final diff = (now.millisecondsSinceEpoch.toDouble() - _lastData!.time) / 1000.0;
      if (diff > 0) {
        final txps = (tx - _lastData!.value[0]) / diff;
        final rxps = (rx - _lastData!.value[1]) / diff;
        final errps = (err - _lastData!.value[2]) / diff;
        setState(() {
          _chartData.add(TimeLineSeries(now.millisecondsSinceEpoch.toDouble(), <double>[txps, rxps, errps]));
          _logs.add(
            DataRow(cells: [
              DataCell(Text(DateFormat("HH:mm:ss").format(now))),
              DataCell(Text(txps.toStringAsFixed(3))),
              DataCell(Text(rxps.toStringAsFixed(3))),
              DataCell(Text(errps.toStringAsFixed(3))),
            ]),
          );
        });
      }
      _lastData = TimeLineSeries(now.millisecondsSinceEpoch.toDouble(), <double>[tx, rx, err]);
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    }
  }

  void _getTragetList() async {
    await _loadMIBDB();
    _targetList = [
      _TrafficTarget("TCP", "tcp", "tcp", ""),
      _TrafficTarget("TCP Connection", "tcpcon", "tcpcon", ""),
      _TrafficTarget("UDP", "udp", "udp", ""),
      _TrafficTarget("IP", "ip", "ip", ""),
      _TrafficTarget("IP Frag", "ipfrag", "ipfrag", ""),
      _TrafficTarget("ICMP", "icmp", "icmp", ""),
      _TrafficTarget("ICMP DestUnreachs", "icmpdu", "icmpdu", ""),
      _TrafficTarget("SNMP", "snmp", "snmp", ""),
    ];
    try {
      var t = InternetAddress(widget.node.ip);
      var session = await Snmp.createSession(t, timeout: Duration(seconds: _timeout), retries: _retry);
      final rootOid = _mibdb!.nameToOid("ifType");
      var currentOid = rootOid;
      while (true) {
        final oid = Oid.fromString(currentOid);
        final message = await session.getNext(oid);
        currentOid = message.pdu.varbinds.first.oid.identifier!;
        if (currentOid.indexOf(rootOid) != 0) {
          break;
        }
        final vbname = _mibdb?.oidToName(message.pdu.varbinds.first.oid.identifier) ?? "";
        final a = vbname.split(".");
        if (a.length != 2) {
          continue;
        }
        final index = a[1];
        var ifType = message.pdu.varbinds.first.value.toString();
        final ifName = await session.get(Oid.fromString(_mibdb!.nameToOid("ifName.$index")));
        if (ifName.pdu.error.value == 0) {
          final name = ifName.pdu.varbinds.first.value.toString();
          _targetList.add(_TrafficTarget("$name:PPS", "ifHCPPS:$index", "ifHCPPS", index));
          _targetList.add(_TrafficTarget("$name:BPS", "ifHCBPS:$index", "ifHCBPS", index));
        } else {
          final name = _getIfName(index, ifType);
          _targetList.add(_TrafficTarget("$name:PPS", "ifPPS:$index", "ifPPS", index));
          _targetList.add(_TrafficTarget("$name:BPS", "ifBPS:$index", "ifBPS", index));
        }
      }
      setState(() {
        _targetMenuItems = [];
        _selectedTarget = "tcp";
        for (var tt in _targetList) {
          _targetMenuItems.add(
            DropdownMenuItem(value: tt.value, child: Text(tt.name)),
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    }
  }

  String _getIfName(String index, String type) {
    switch (type) {
      case "6":
        return "Ether($index)";
      case "24":
        return "Loopback($index)";
    }
    return "Other($type:$index)";
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _timer = null;
    });
  }

  List<LineChartBarData> _createChartData() {
    List<LineChartBarData> ret = [];
    ret.add(LineChartBarData(spots: [], color: Colors.blue));
    ret.add(LineChartBarData(spots: [], color: Colors.green));
    ret.add(LineChartBarData(spots: [], color: Colors.red));
    for (var d in _chartData) {
      for (var i = 0; i < ret.length; i++) {
        ret[i].spots.add(FlSpot(d.time, d.value[i]));
      }
    }
    return ret;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool dark = Theme.of(context).brightness == Brightness.dark;
    loc = AppLocalizations.of(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${loc?.traffic} ${widget.node.name}"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          scrollDirection: Axis.vertical,
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(children: [
                  Expanded(child: Text(loc!.target)),
                  DropdownButton<String>(
                      value: _selectedTarget,
                      items: _targetMenuItems,
                      onChanged: (value) => {
                            setState(() {
                              _selectedTarget = value!;
                            })
                          }),
                ]),
                Row(
                  children: [
                    Expanded(child: Text("${loc?.interval}(${_interval.toInt()}${loc?.sec})")),
                    Slider(
                        label: "${_interval.toInt()}${loc?.sec}",
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
                SizedBox(
                  height: 200,
                  child: TimeLineChart(_createChartData()),
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
                          label: Text(loc!.time),
                        ),
                        DataColumn(
                          label: Text('${loc!.tx}($_unit)', style: const TextStyle(color: Colors.blue)),
                        ),
                        DataColumn(
                          label: Text('${loc!.rx}($_unit)', style: const TextStyle(color: Colors.green)),
                        ),
                        DataColumn(
                          label: Text('${loc!.error}($_unit)', style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                      rows: _logs,
                    )),
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

// Trafficの取得先
class _TrafficTarget {
  String value;
  String name;
  String type;
  String index;
  _TrafficTarget(this.name, this.value, this.type, this.index);
}
