import 'package:flutter/material.dart';
import 'package:statistics/statistics.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/ping_chart.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:twsnmpfm/settings.dart';

class PingPage extends StatefulWidget {
  final String ip;
  final Settings settings;
  const PingPage({Key? key, required this.ip, required this.settings}) : super(key: key);

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
  final List<TimeSeriesPingRTT> _chartData = [];
  String _lastResult = "";
  Ping? ping;
  AppLocalizations? loc;
  bool _err = false;

  @override
  void initState() {
    _count = widget.settings.count.toDouble();
    _timeout = widget.settings.timeout.toDouble();
    _ttl = widget.settings.ttl.toDouble();
    super.initState();
  }

  void _startPing() {
    int i = 0;
    _stats.length = 0;
    _chartData.length = 0;
    _maxTTL = 0;
    _minTTL = 255;
    _rtts.length = 0;
    _err = false;
    ping = Ping(widget.ip, count: _count.toInt(), timeout: _timeout.toInt(), ttl: _ttl.toInt());
    ping?.stream.listen((event) {
      final ttl = event.response?.ttl ?? '';
      setState(() {
        if (ttl != '') {
          final nrtt = event.response?.time?.inMicroseconds.toDouble() ?? 0.0;
          _rtts.add(nrtt / 1000);
          _chartData.add(TimeSeriesPingRTT(DateTime.now(), nrtt / 1000));
          final nttl = ttl.toString().toInt();
          if (nttl < _minTTL) {
            _minTTL = nttl;
          }
          if (nttl > _maxTTL) {
            _maxTTL = nttl;
          }
          i++;
          setState(() {
            _lastResult = '$i/$_count rtt=${nrtt / 1000}mSec ttl=$ttl';
            _setStats();
          });
        } else {
          setState(() {
            final err = event.error?.toString() ?? '';
            if (err == "") {
              final tx = event.summary?.transmitted ?? 0;
              final rx = event.summary?.received ?? 0;
              _lastResult = "ping done $rx/$tx";
            } else {
              _lastResult = err;
              _err = true;
            }
            _setStats();
            ping = null;
          });
        }
      });
    });
  }

  _stopPing() {
    ping?.stop();
    setState(() {
      ping = null;
    });
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

  List<charts.Series<TimeSeriesPingRTT, DateTime>> _createChartData() {
    return [
      charts.Series<TimeSeriesPingRTT, DateTime>(
        id: 'RTT',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesPingRTT pd, _) => pd.time,
        measureFn: (TimeSeriesPingRTT pd, _) => pd.rtt,
        data: _chartData,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    loc = AppLocalizations.of(context)!;
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
                    Slider(
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
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text("${loc!.timeout}(${_timeout.toInt()}${loc!.sec})")),
                    Slider(
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
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text("TTL(${_ttl.toInt()})")),
                    Slider(
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
                  ],
                ),
                Text(
                  _lastResult,
                  style: TextStyle(fontSize: 16, color: _err ? Colors.red : Colors.black87),
                ),
                SizedBox(
                  height: 200,
                  child: PingChart(_createChartData()),
                ),
                DataTable(
                  headingTextStyle: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 16,
                  ),
                  headingRowHeight: 22,
                  dataTextStyle: const TextStyle(color: Colors.black, fontSize: 14),
                  dataRowHeight: 20,
                  columns: const [
                    DataColumn(
                      label: Text('??????'),
                    ),
                    DataColumn(
                      label: Text('???'),
                    ),
                  ],
                  rows: _stats,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
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
    );
  }
}
