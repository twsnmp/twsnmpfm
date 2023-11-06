import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:dart_snmp/dart_snmp.dart';
import 'package:twsnmpfm/settings.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:statistics/statistics.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:twsnmpfm/time_line_chart.dart';

class HostResourcePage extends StatefulWidget {
  final Node node;
  final Settings settings;
  const HostResourcePage({super.key, required this.node, required this.settings});

  @override
  State<HostResourcePage> createState() => _HostResourceState();
}

class _HostResourceState extends State<HostResourcePage> {
  double _interval = 5;
  int _timeout = 1;
  int _retry = 1;

  final List<TimeLineSeries> _chartData = [];
  List<LineChartBarData> _chartSeries = [];
  List<DataRow> _rows = [];
  String _errorMsg = '';
  MIBDB? _mibdb;
  Timer? _timer;
  final List<Color> colors = [Colors.blue, Colors.green, Colors.yellow, Colors.cyan, Colors.orange, Colors.pink, Colors.blueGrey, Colors.teal];

  @override
  void initState() {
    _interval = widget.settings.interval.toDouble();
    _timeout = widget.settings.timeout;
    _retry = widget.settings.retry;
    _loadMIBDB();
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
    _chartData.length = 0;
    _getHostResource();
    _timer = Timer.periodic(Duration(seconds: _interval.toInt()), _getHostResourceTimer);
  }

  void _getHostResourceTimer(Timer t) async {
    _getHostResource();
  }

  void _getHostResource() async {
    try {
      var t = InternetAddress(widget.node.ip);
      var session = await Snmp.createSession(t, timeout: Duration(seconds: _timeout), retries: _retry);
      String n = "hrProcessorLoad";
      final List<double> cpus = [];
      final List<Storage> storages = [];
      while (true) {
        var m = await session.getNext(Oid.fromString(_mibdb!.nameToOid(n)));
        if (m.pdu.error.value != 0) {
          log.warning(m.pdu.error.toString());
          break;
        }
        n = _mibdb!.oidToName(m.pdu.varbinds.first.oid.identifier);
        if (!n.startsWith("hrProcessorLoad")) {
          break;
        }
        cpus.add(double.parse(m.pdu.varbinds.first.value.toString()));
      }
      n = "hrStorageType";
      while (true) {
        var m = await session.getNext(Oid.fromString(_mibdb!.nameToOid(n)));
        if (m.pdu.error.value != 0) {
          log.warning(m.pdu.error.toString());
          break;
        }
        n = _mibdb!.oidToName(m.pdu.varbinds.first.oid.identifier);
        if (!n.startsWith("hrStorageType")) {
          break;
        }
        final t = _mibdb!.oidToName(m.pdu.varbinds.first.value.toString());
        if (t != "hrStorageRam" && t != "hrStorageFixedDisk") {
          continue;
        }
        final a = n.split(".");
        if (a.length != 2) {
          log.warning(m.pdu.error.toString());
          continue;
        }
        final index = a[1];
        m = await session.get(Oid.fromString(_mibdb!.nameToOid("hrStorageDescr.$index")));
        if (m.pdu.error.value != 0 || m.pdu.varbinds.first.tag > 70) {
          log.warning(m.pdu.error.toString());
          continue;
        }
        final name = t == "hrStorageRam" ? "Mem" : "Disk:${m.pdu.varbinds.first.value}";
        if (name.contains(":/run") || name.contains(":/sys") || name.contains(":/dev") || name.contains(":/var/lib/docker") || name.contains(":/boot")) {
          continue;
        }
        m = await session.get(Oid.fromString(_mibdb!.nameToOid("hrStorageSize.$index")));
        if (m.pdu.error.value != 0 || m.pdu.varbinds.first.tag > 70) {
          log.warning(m.pdu.error.toString());
          continue;
        }
        final size = double.parse(m.pdu.varbinds.first.value.toString());
        m = await session.get(Oid.fromString(_mibdb!.nameToOid("hrStorageUsed.$index")));
        if (m.pdu.error.value != 0 || m.pdu.varbinds.first.tag > 70) {
          log.warning(m.pdu.error.toString());
          continue;
        }
        final used = double.parse(m.pdu.varbinds.first.value.toString());
        m = await session.get(Oid.fromString(_mibdb!.nameToOid("hrStorageAllocationUnits.$index")));
        if (m.pdu.error.value != 0 || m.pdu.varbinds.first.tag > 70) {
          log.warning(m.pdu.error.toString());
          continue;
        }
        final unit = double.parse(m.pdu.varbinds.first.value.toString());
        storages.add(Storage(name, size, used, unit));
      }
      final List<double> vals = [];
      final cpustats = cpus.statistics;
      vals.add(cpustats.mean);
      for (var s in storages) {
        vals.add(s.usage());
      }
      final now = DateTime.now().millisecondsSinceEpoch.toDouble();
      setState(() {
        _chartData.add(TimeLineSeries(now, vals));
        _chartSeries = _createChartSeries(storages);
        _rows = [];
        _rows.add(DataRow(cells: [
          const DataCell(Text(
            "CPU Avg",
            style: TextStyle(color: Colors.red),
          )),
          DataCell(Text("${vals[0].toStringAsFixed(2)}%")),
        ]));
        for (var i = 0; i < cpus.length; i++) {
          _rows.add(DataRow(cells: [
            DataCell(Text("CPU${i + 1}")),
            DataCell(Text("${cpus[i].toStringAsFixed(2)}%")),
          ]));
        }
        storages.asMap().forEach((i, s) {
          _rows.add(DataRow(cells: [
            DataCell(Text(
              s.name,
              style: TextStyle(color: colors[i % colors.length]),
            )),
            DataCell(Text(s.info())),
          ]));
        });
      });
      session.close();
    } catch (e) {
      if (_timer != null) {
        setState(() {
          _errorMsg = e.toString();
        });
      }
    }
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _timer = null;
    });
  }

  List<LineChartBarData> _createChartSeries(List<Storage> storages) {
    List<LineChartBarData> r = [];
    final bool showDot = _chartData.length < 10;
    r.add(LineChartBarData(
      color: Colors.red[600],
      spots: [],
      dotData: FlDotData(show: showDot),
    ));
    for (var i = 0; i < storages.length; i++) {
      r.add(LineChartBarData(
        color: colors[i % colors.length],
        dotData: FlDotData(show: showDot),
        spots: [],
      ));
    }
    for (var i = 0; i < _chartData.length; i++) {
      r[0].spots.add(FlSpot(_chartData[i].time, _chartData[i].value[0]));
      for (var j = 0; j < storages.length; j++) {
        if (_chartData[i].value.length >= j) {
          r[j + 1].spots.add(FlSpot(_chartData[i].time, _chartData[i].value[j + 1]));
        }
      }
    }
    return r;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool dark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${loc.hostResource} ${widget.node.name}"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          scrollDirection: Axis.vertical,
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                  height: 160,
                  child: TimeLineChart(_chartSeries),
                ),
                const SizedBox(height: 10),
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
                        DataColumn(label: Text(loc.key)),
                        DataColumn(label: Text(loc.value)),
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

class Storage {
  String name;
  double size;
  double used;
  double unit;
  Storage(this.name, this.size, this.used, this.unit);

  double usage() {
    if (size > 0) {
      return 100.0 * used / size;
    }
    return 0.0;
  }

  String info() {
    return "${formatBytes(used * unit)}/${formatBytes(size * unit)}(${usage().toStringAsFixed(2)}%)";
  }

  String formatBytes(double b) {
    final bytes = b.toInt();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (math.log(bytes) / math.log(1024)).floor();
    return "${((bytes / math.pow(1024, i)).toStringAsFixed(3))} ${suffixes[i]}";
  }
}
