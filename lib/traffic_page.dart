import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:dart_snmp/dart_snmp.dart';
import 'package:twsnmpfm/settings.dart';
import 'dart:async';
import 'package:twsnmpfm/time_line_chart.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class TrafficPage extends StatefulWidget {
  final Node node;
  final Settings settings;
  const TrafficPage({Key? key, required this.node, required this.settings}) : super(key: key);

  @override
  State<TrafficPage> createState() => _TrafficState();
}

class _TrafficState extends State<TrafficPage> {
  String _selectedTarget = '';
  double _interval = 5;
  int _timeout = 1;
  int _retry = 1;

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
        break;
      case "udp":
        _txMIBs = ["udpOutDatagrams.0"];
        _rxMIBs = ["udpInDatagrams.0"];
        _errorMIBs = ["udpNoPorts.0", "udpInErrors.0"];
        break;
      case "ifPPS":
        _txMIBs = ["ifOutUcastPkts.$index", "ifOutUcastPkts.$index"];
        _rxMIBs = ["ifInUcastPkts.$index", "ifInUcastPkts.$index"];
        _errorMIBs = ["ifInDiscards.$index", "ifInErrors.$index", "ifInUnknownProtos.$index"];
        break;
      case "ifHCPPS":
        _txMIBs = ["ifHCOutUcastPkts.$index", "ifHCOutMulticastPkts.$index", "ifHCOutBroadcastPkts.$index"];
        _rxMIBs = ["ifHCInUcastPkts.$index", "ifHCInMulticastPkts.$index", "ifHCInBroadcastPkts.$index"];
        _errorMIBs = ["ifInDiscards.$index", "ifInErrors.$index", "ifInUnknownProtos.$index"];
        break;
      case "ifBPS":
        _txMIBs = ["ifOutOctets.$index"];
        _rxMIBs = ["ifInOctets.$index"];
        _errorMIBs = [];
        break;
      case "ifHCBPS":
        _txMIBs = ["ifHCOutOctets.$index"];
        _rxMIBs = ["ifHCInOctets.$index"];
        _errorMIBs = [];
        break;
    }
    _getTraffic();
    _timer = Timer.periodic(Duration(seconds: _interval.toInt()), _getTrafficTimer);
    _chartData.length = 0;
    setState(() {
      _lastData = null;
    });
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
          continue;
        }
        tx += double.parse(m.pdu.varbinds.first.value.toString());
      }
      for (var n in _rxMIBs) {
        var m = await session.get(Oid.fromString(_mibdb!.nameToOid(n)));
        if (m.pdu.error.value != 0) {
          continue;
        }
        rx += double.parse(m.pdu.varbinds.first.value.toString());
      }
      for (var n in _errorMIBs) {
        var m = await session.get(Oid.fromString(_mibdb!.nameToOid(n)));
        if (m.pdu.error.value != 0) {
          continue;
        }
        err += double.parse(m.pdu.varbinds.first.value.toString());
      }
      final now = DateTime.now();
      session.close();
      if (_lastData == null) {
        _lastData = TimeLineSeries(now, tx, rx, err);
        return;
      }
      final diff = (now.second - _lastData!.time.second).toDouble();
      if (diff > 0) {
        final txps = (tx - _lastData!.tx) / diff;
        final rxps = (rx - _lastData!.rx) / diff;
        final errps = (err - _lastData!.error) / diff;
        setState(() {
          _chartData.add(TimeLineSeries(now, txps, rxps, errps));
        });
      }
      _lastData = TimeLineSeries(now, tx, rx, err);
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
      _TrafficTarget("UDP", "udp", "udp", ""),
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

  List<charts.Series<TimeLineSeries, DateTime>> _createChartData() {
    return [
      charts.Series<TimeLineSeries, DateTime>(
        id: 'Tx',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeLineSeries t, _) => t.time,
        measureFn: (TimeLineSeries t, _) => t.tx,
        data: _chartData,
      ),
      charts.Series<TimeLineSeries, DateTime>(
        id: 'Rx',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (TimeLineSeries t, _) => t.time,
        measureFn: (TimeLineSeries t, _) => t.rx,
        data: _chartData,
      ),
      charts.Series<TimeLineSeries, DateTime>(
        id: 'Error',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (TimeLineSeries t, _) => t.time,
        measureFn: (TimeLineSeries t, _) => t.error,
        data: _chartData,
      )
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${loc.traffic} ${widget.node.name}"),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(children: [
                  Expanded(child: Text(loc.target)),
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
                SizedBox(
                  height: 200,
                  child: TimeLineChart(_createChartData()),
                ),
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
