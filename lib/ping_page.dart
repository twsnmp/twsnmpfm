import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:statistics/statistics.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:twsnmpfm/l10n/app_localizations.dart';
import 'package:twsnmpfm/settings.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:twsnmpfm/time_line_chart.dart';

class PingPage extends StatefulWidget {
  final String ip;
  final Settings settings;
  const PingPage({super.key, required this.ip, required this.settings});

  @override
  State<PingPage> createState() => _PingPageState();
}

class _PingPageState extends State<PingPage> {
  double _count = 5;
  double _timeout = 2;
  double _ttl = 255;
  int _maxTTL = 0;
  int _minTTL = 255;
  final List<DataRow> _stats = [];
  final List<num> _rtts = [];
  final List<TimeLineSeries> _chartData = [];
  String _lastResult = "";
  String _errMsg = "";
  Ping? ping;
  AppLocalizations? loc;
  bool _beep = false;

  @override
  void initState() {
    _count = widget.settings.count.toDouble();
    _timeout = widget.settings.timeout.toDouble();
    _ttl = widget.settings.ttl.toDouble();
    super.initState();
  }

  void _startPing() {
    int i = 0;
    _stats.clear();
    _chartData.clear();
    _maxTTL = 0;
    _minTTL = 255;
    _rtts.clear();
    _errMsg = "";
    ping = Ping(widget.ip,
        count: _count.toInt(), timeout: _timeout.toInt(), ttl: _ttl.toInt());
    ping?.stream.listen((event) {
      if (!mounted) return;
      final response = event.response;
      if (response != null && response.ttl != null) {
        final ttl = response.ttl!;
        i++;
        final err = event.error?.toString() ?? '';
        if (_beep) {
          SystemSound.play(SystemSoundType.click);
        }
        if (!mounted) return;
        setState(() {
          if (err != '') {
            _lastResult = '$i/$_count rtt=? ttl=?';
            _errMsg = err;
          } else {
            final nrtt = response.time?.inMicroseconds.toDouble() ?? 0.0;
            _rtts.add(nrtt / 1000);
            _chartData.add(TimeLineSeries(
                DateTime.now().millisecondsSinceEpoch.toDouble(),
                [nrtt / 1000]));
            if (ttl < _minTTL) {
              _minTTL = ttl;
            }
            if (ttl > _maxTTL) {
              _maxTTL = ttl;
            }
            _lastResult = '$i/$_count rtt=${nrtt / 1000}mSec ttl=$ttl';
          }
          _setStats();
        });
      } else {
        if (!mounted) return;
        setState(() {
          final err = event.error?.toString() ?? '';
          if (err == "") {
            final summary = event.summary;
            if (summary != null) {
              final tx = summary.transmitted;
              final rx = summary.received;
              _lastResult = "ping done $rx/$tx";
              _setStats();
              ping?.stop();
              ping = null;
            }
          } else {
            _lastResult = err;
            _errMsg = err;
          }
        });
      }
    });
  }

  void _stopPing() {
    ping?.stop();
    setState(() {
      ping = null;
    });
  }

  @override
  void dispose() {
    ping?.stop();
    super.dispose();
  }

  void _setStats() {
    if (_rtts.isEmpty) {
      return;
    }
    _stats.length = 0;
    var statistics = _rtts.statistics;
    _stats.add(
      DataRow(cells: [
        DataCell(Text("${loc!.max} TTL")),
        DataCell(Text("$_maxTTL")),
      ]),
    );
    _stats.add(
      DataRow(cells: [
        DataCell(Text("${loc!.min} TTL")),
        DataCell(Text("$_minTTL")),
      ]),
    );
    _stats.add(
      DataRow(cells: [
        DataCell(Text("${loc!.max} RTT(mSec)")),
        DataCell(Text(statistics.max.toStringAsFixed(3))),
      ]),
    );
    _stats.add(
      DataRow(cells: [
        DataCell(Text("${loc!.min} RTT(mSec)")),
        DataCell(Text(statistics.min.toStringAsFixed(3))),
      ]),
    );
    _stats.add(
      DataRow(cells: [
        DataCell(Text("${loc!.mean} RTT(mSec)")),
        DataCell(Text(statistics.mean.toStringAsFixed(3))),
      ]),
    );
    _stats.add(
      DataRow(cells: [
        DataCell(Text("${loc!.median} RTT(mSec)")),
        DataCell(Text(statistics.median.toStringAsFixed(3))),
      ]),
    );
    _stats.add(
      DataRow(cells: [
        DataCell(Text(loc!.sd)),
        DataCell(Text(statistics.standardDeviation.toStringAsFixed(3))),
      ]),
    );
  }

  List<LineChartBarData> _createChartData() {
    final List<FlSpot> spots = [];
    for (var i = 0; i < _chartData.length; i++) {
      spots.add(FlSpot(_chartData[i].time, _chartData[i].value[0]));
    }
    return [
      LineChartBarData(
        spots: spots,
        dotData: FlDotData(show: spots.length < 10),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Ping ${widget.ip}"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: [
                    Expanded(child: Text("${loc!.count}(${_count.toInt()})")),
                    Semantics(
                      identifier: "ping_count_slider",
                      child: Slider(
                          label: "${_count.toInt()}",
                          value: _count,
                          min: 1,
                          max: 100,
                          divisions: (100 - 1),
                          onChanged: (value) => {
                                setState(() {
                                  _count = value;
                                })
                              }),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text("${loc!.timeout}(${_timeout.toInt()}${loc!.sec})")),
                    Semantics(
                      identifier: "ping_timeout_slider",
                      child: Slider(
                          label: "${_timeout.toInt()}",
                          value: _timeout,
                          min: 1,
                          max: 10,
                          divisions: (10 - 1),
                          onChanged: (value) => {
                                setState(() {
                                  _timeout = value;
                                })
                              }),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text("TTL(${_ttl.toInt()})")),
                    Semantics(
                      identifier: "ping_ttl_slider",
                      child: Slider(
                          label: "${_ttl.toInt()}",
                          value: _ttl,
                          min: 1,
                          max: 255,
                          divisions: (255 - 1),
                          onChanged: (value) => {
                                setState(() {
                                  _ttl = value;
                                })
                              }),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(child: Text("BEEP")),
                    Semantics(
                      identifier: "ping_beep_switch",
                      child: Switch(
                        value: _beep,
                        onChanged: (bool value) {
                          setState(() {
                            _beep = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Text(
                  _lastResult,
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                ),
                Text(
                  _errMsg,
                  style: TextStyle(fontSize: 12, color: colorScheme.error),
                ),
                ExcludeSemantics(
                  child: SizedBox(
                    height: 160,
                    child: TimeLineChart(_createChartData()),
                  ),
                ),
                ExcludeSemantics(
                  child: Semantics(
                    identifier: "ping_stats_table",
                    child: DataTable(
                      headingRowHeight: 20,
                      dataRowMinHeight: 10,
                      dataRowMaxHeight: 18,
                      columns: const [
                        DataColumn(label: Text('項目')),
                        DataColumn(label: Text('値')),
                      ],
                      rows: _stats,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Semantics(
          container: true,
          identifier: "ping_fab",
          child: FloatingActionButton(
            onPressed: () {
              if (ping != null) {
                _stopPing();
              } else {
                _startPing();
              }
            },
            child: ping != null ? const Icon(Icons.stop, color: Colors.red) : const Icon(Icons.play_circle),
          ),
        ),
      ),
    );
  }
}
