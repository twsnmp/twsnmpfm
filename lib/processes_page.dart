import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:dart_snmp/dart_snmp.dart';
import 'package:twsnmpfm/settings.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

class ProcessesPage extends StatefulWidget {
  final Node node;
  final Settings settings;
  const ProcessesPage({super.key, required this.node, required this.settings});

  @override
  State<ProcessesPage> createState() => _ProcessesState();
}

class _ProcessesState extends State<ProcessesPage> {
  double _interval = 5;
  int _timeout = 1;
  int _retry = 1;

  List<DataRow> _rows = [];
  final Map<String, int> _startCpuMap = {};
  List<PieChartSectionData> _sections = [];
  String _errorMsg = '';
  MIBDB? _mibdb;
  Timer? _timer;
  bool _sortCPU = true;

  @override
  void initState() {
    _interval = widget.settings.interval.toDouble();
    if (_interval < 30) {
      _interval = 30;
    }
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
    _startCpuMap.clear();
    _getProcesses();
    _timer = Timer.periodic(Duration(seconds: _interval.toInt()), _getProcessesTimer);
  }

  void _getProcessesTimer(Timer t) async {
    _getProcesses();
  }

  void _getProcesses() async {
    try {
      final List<Process> processes = [];
      int totalCPU = 0;
      int totalMem = 0;
      var t = InternetAddress(widget.node.ip);
      var c = widget.node.community.isEmpty ? "public" : widget.node.community;
      var session = await Snmp.createSession(t, timeout: Duration(seconds: _timeout), retries: _retry, community: c);
      String n = "hrSWRunName";
      while (true) {
        var m = await session.getNext(Oid.fromString(_mibdb!.nameToOid(n)));
        if (m.pdu.error.value != 0) {
          log.warning(m.pdu.error.toString());
          break;
        }
        n = _mibdb!.oidToName(m.pdu.varbinds.first.oid.identifier);
        if (!n.startsWith("hrSWRunName")) {
          break;
        }
        final a = n.split(".");
        if (a.length != 2) {
          log.warning(m.pdu.error.toString());
          continue;
        }
        final index = a[1];
        final name = _mibdb!.oidToName(m.pdu.varbinds.first.value.toString());

        m = await session.get(Oid.fromString(_mibdb!.nameToOid("hrSWRunType.$index")));
        if (m.pdu.error.value != 0 || m.pdu.varbinds.first.tag > 70) {
          log.warning(m.pdu.error.toString());
          continue;
        }
        final type = int.parse(m.pdu.varbinds.first.value.toString());

        m = await session.get(Oid.fromString(_mibdb!.nameToOid("hrSWRunStatus.$index")));
        if (m.pdu.error.value != 0 || m.pdu.varbinds.first.tag > 70) {
          log.warning(m.pdu.error.toString());
          continue;
        }
        final status = int.parse(m.pdu.varbinds.first.value.toString());

        m = await session.get(Oid.fromString(_mibdb!.nameToOid("hrSWRunPath.$index")));
        if (m.pdu.error.value != 0 || m.pdu.varbinds.first.tag > 70) {
          log.warning(m.pdu.error.toString());
          continue;
        }
        final path = m.pdu.varbinds.first.value.toString();

        m = await session.get(Oid.fromString(_mibdb!.nameToOid("hrSWRunPerfCPU.$index")));
        if (m.pdu.error.value != 0 || m.pdu.varbinds.first.tag > 70) {
          log.warning(m.pdu.error.toString());
          continue;
        }
        var cpu = int.parse(m.pdu.varbinds.first.value.toString());
        if (!_startCpuMap.containsKey(index)) {
          // 初回はそのまま使う
          _startCpuMap[index] = cpu;
        } else {
          cpu -= _startCpuMap[index] ?? 0;
        }
        totalCPU += cpu;

        m = await session.get(Oid.fromString(_mibdb!.nameToOid("hrSWRunPerfMem.$index")));
        if (m.pdu.error.value != 0 || m.pdu.varbinds.first.tag > 70) {
          log.warning(m.pdu.error.toString());
          continue;
        }
        var mem = int.parse(m.pdu.varbinds.first.value.toString());
        totalMem += mem;
        processes.add(Process(name, path, type, status, cpu, mem));
      }
      final List<ProcessData> topCPU = [];
      final List<ProcessData> topMem = [];
      for (var p in processes) {
        p.cpuRate = totalCPU > 0 ? (p.cpu.toDouble() * 100.0) / totalCPU.toDouble() : 0.0;
        p.memRate = totalMem > 0 ? (p.mem.toDouble() * 100.0) / totalMem.toDouble() : 0.0;
        topCPU.add(ProcessData(p.name, p.cpuRate ?? 0.0));
        topMem.add(ProcessData(p.name, p.memRate ?? 0.0));
      }
      topCPU.sort((a, b) => b.value.compareTo(a.value));
      while (topCPU.length > 5) {
        topCPU.removeLast();
      }
      double otherCPU = 100.0;
      for (var c in topCPU) {
        otherCPU -= c.value;
      }

      topMem.sort((a, b) => b.value.compareTo(a.value));
      while (topMem.length > 5) {
        topMem.removeLast();
      }
      double otherMem = 100.0;
      for (var m in topMem) {
        otherMem -= m.value;
      }
      if (_sortCPU) {
        processes.sort((a, b) => b.cpu.compareTo(a.cpu));
      } else {
        processes.sort((a, b) => b.mem.compareTo(a.mem));
      }
      setState(() {
        _rows = [];
        _sections = [];
        for (var p in processes) {
          _rows.add(DataRow(cells: [
            DataCell(Text(p.name)),
            DataCell(Text(p.path)),
            DataCell(Text(p.getStatusName())),
            DataCell(Text(p.getTypeName())),
            DataCell(Text("${p.cpuRate?.toStringAsFixed(2)}%")),
            DataCell(Text("${p.memRate?.toStringAsFixed(2)}%")),
            DataCell(Text(p.getMemBytes())),
          ]));
        }
        final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue];
        if (_sortCPU) {
          for (var i = 0; i < topCPU.length; i++) {
            _sections.add(PieChartSectionData(
              title: topCPU[i].name,
              value: topCPU[i].value,
              color: colors[i],
              titleStyle: const TextStyle(fontSize: 10),
            ));
          }
          _sections.add(PieChartSectionData(
            title: "Other",
            value: otherCPU,
            color: Colors.blueGrey,
            titleStyle: const TextStyle(fontSize: 10),
          ));
        } else {
          for (var i = 0; i < topMem.length; i++) {
            _sections.add(PieChartSectionData(
              title: topMem[i].name,
              value: topMem[i].value,
              color: colors[i],
              titleStyle: const TextStyle(fontSize: 10),
            ));
          }
          _sections.add(PieChartSectionData(
            title: "Other",
            value: otherMem,
            color: Colors.blueGrey,
            titleStyle: const TextStyle(fontSize: 10),
          ));
        }
      });
      session.close();
    } catch (e) {
      if (_timer != null) {
        setState(() {
          _errorMsg = e.toString();
        });
        _stop();
      }
    }
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _timer = null;
    });
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
          title: Text("${loc.processes} ${widget.node.name}"),
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
                    Expanded(child: Text("${loc.showProcessMode}:${_sortCPU ? 'CPU' : 'Mem'}")),
                    Switch(
                      value: _sortCPU,
                      onChanged: (bool value) {
                        setState(() {
                          _sortCPU = value;
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
                        min: 30,
                        max: 300,
                        divisions: (300 - 30) ~/ 5,
                        onChanged: (value) => {
                              setState(() {
                                _interval = value;
                              })
                            }),
                  ],
                ),
                Text(_errorMsg, style: const TextStyle(color: Colors.red)),
                SizedBox(
                  height: 250,
                  child: PieChart(PieChartData(sections: _sections)),
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
                        DataColumn(label: Text(loc.processName)),
                        DataColumn(label: Text(loc.path)),
                        DataColumn(label: Text(loc.status)),
                        DataColumn(label: Text(loc.type)),
                        const DataColumn(label: Text("CPU%")),
                        const DataColumn(label: Text("Mem%")),
                        const DataColumn(label: Text("Mem(Bytes)"))
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

class Process {
  String name;
  String path;
  int type;
  int status;
  int cpu;
  int mem;
  double? cpuRate;
  double? memRate;

  Process(this.name, this.path, this.type, this.status, this.cpu, this.mem);

  String getTypeName() {
    switch (type) {
      case 2:
        return "OS";
      case 3:
        return "Driver";
      case 4:
        return "Application";
    }
    return "Unknown";
  }

  String getStatusName() {
    switch (status) {
      case 1:
        return "Running";
      case 2:
        return "Runnable";
      case 3:
        return "NotRunnable";
      case 4:
        return "Invalid";
    }
    return "Unknown";
  }

  String getMemBytes() {
    if (mem > 1024 * 1024) {
      return "${(mem.toDouble() / (1024 * 1024)).toStringAsFixed(3)}GB";
    } else if (mem > 1024) {
      return "${(mem.toDouble() / 1024).toStringAsFixed(3)}MB";
    }
    return "${mem}KB";
  }
}

class ProcessData {
  final String name;
  final double value;
  ProcessData(this.name, this.value);
}
