import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'package:twsnmpfm/ntp_chart.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/services.dart' show rootBundle;
import 'package:twsnmpfm/settings.dart';
import 'package:statistics/statistics.dart';
import 'dart:async';
import 'package:ntp/ntp.dart';

class ServerTestPage extends StatefulWidget {
  final Node node;
  final Settings settings;
  const ServerTestPage({Key? key, required this.node, required this.settings}) : super(key: key);

  @override
  State<ServerTestPage> createState() => _ServerTestState();
}

class _ServerTestState extends State<ServerTestPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  AppLocalizations? loc;
  double _timeout = 2;
  String _target = '';
  final List<String> _targetList = [];
  String _errorMsg = '';
  String _lastResult = '';
  bool _process = false;
  MIBDB? _mibdb;
  final List<DataRow> _ntpStats = [];
  final List<num> _ntpOffset = [];
  final List<TimeSeriesNTPOffset> _ntpChartData = [];
  Timer? _timer;

  _ServerTestState() {
    _loadMIBDB();
  }

  @override
  void initState() {
    _timeout = widget.settings.timeout.toDouble();
    _target = widget.node.ip;
    _targetList.add(_target);
    _targetList.add(widget.node.name);
    _targetList.add("time.windows.com");
    _targetList.add("ntp.nict.jp");
    _targetList.add("time.asia.apple.com");
    _targetList.add("ntp.jst.mfeed.ad.jp");
    _targetList.add("time.cloudflare.com");
    super.initState();
    _tabController = TabController(vsync: this, length: 4);
    _tabController?.addListener(() {
      _stop();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _loadMIBDB() async {
    final mibfile = await rootBundle.loadString('assets/conf/mib.txt');
    _mibdb = MIBDB(mibfile);
  }

  SingleChildScrollView _ntpTestView() => SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(loc!.server, style: const TextStyle(color: Colors.blue)),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _target),
                optionsBuilder: (value) {
                  if (value.text.isEmpty) {
                    return [];
                  }
                  _target = value.text;
                  return _targetList.where((n) => n.toLowerCase().contains(value.text.toLowerCase()));
                },
                onSelected: (value) {
                  setState(() {
                    _target = value;
                  });
                },
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
              Text(
                _lastResult,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              Text(
                _errorMsg,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
              SizedBox(
                height: 180,
                child: NTPChart(_createNTPChartData()),
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
                    label: Text('項目'),
                  ),
                  DataColumn(
                    label: Text('値'),
                  ),
                ],
                rows: _ntpStats,
              ),
            ],
          ),
        ),
      );
  void _setNTPStats() {
    if (_ntpOffset.isEmpty) {
      return;
    }
    _ntpStats.length = 0;
    var statistics = _ntpOffset.statistics;
    _ntpStats.add(
      DataRow(cells: [
        DataCell(Text("${loc!.max}(mSec)")),
        DataCell(Text(statistics.max.toStringAsFixed(3))),
      ]),
    );
    _ntpStats.add(
      DataRow(cells: [
        DataCell(Text("${loc!.min}(mSec)")),
        DataCell(Text(statistics.min.toStringAsFixed(3))),
      ]),
    );
    _ntpStats.add(
      DataRow(cells: [
        DataCell(Text("${loc!.mean}(mSec)")),
        DataCell(Text(statistics.mean.toStringAsFixed(3))),
      ]),
    );
    _ntpStats.add(
      DataRow(cells: [
        DataCell(Text("${loc!.median}(mSec)")),
        DataCell(Text(statistics.median.toStringAsFixed(3))),
      ]),
    );
    _ntpStats.add(
      DataRow(cells: [
        DataCell(Text(loc!.sd)),
        DataCell(Text(statistics.standardDeviation.toStringAsFixed(3))),
      ]),
    );
  }

  List<charts.Series<TimeSeriesNTPOffset, DateTime>> _createNTPChartData() {
    return [
      charts.Series<TimeSeriesNTPOffset, DateTime>(
        id: 'DIFF',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesNTPOffset pd, _) => pd.time,
        measureFn: (TimeSeriesNTPOffset pd, _) => pd.diff,
        data: _ntpChartData,
      )
    ];
  }

  void _startNTPTest() {
    if (_timer != null) {
      return;
    }
    setState(() {
      _lastResult = "";
      _errorMsg = "";
      _process = true;
      _ntpChartData.length = 0;
      _ntpOffset.length = 0;
    });
    _ntpTest();
    _timer = Timer.periodic(const Duration(seconds: 15), _ntpTestTimer);
  }

  void _ntpTestTimer(Timer t) {
    _ntpTest();
  }

  void _ntpTest() async {
    try {
      setState(() {
        _errorMsg = "";
      });
      final int offset = await NTP.getNtpOffset(localTime: DateTime.now(), lookUpAddress: _target, timeout: Duration(seconds: _timeout.toInt()));
      setState(() {
        _lastResult = "offset $offset mSec";
        _ntpChartData.add(TimeSeriesNTPOffset(DateTime.now(), offset.toDouble()));
        _ntpOffset.add(offset);
        _setNTPStats();
      });
      if (_ntpOffset.length > 100) {
        _stop();
      }
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
      _stop();
    }
  }

  void _start() {
    final index = _tabController?.index ?? 0;
    switch (index) {
      case 0:
        // NTP Test
        _startNTPTest();
        break;
      case 1:
        break;
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
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
        title: Text("${loc!.serverTest} ${widget.node.name}"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: Text("NTP"),
            ),
            Tab(
              child: Text("syslog"),
            ),
            Tab(
              child: Text("TRAP"),
            ),
            Tab(
              child: Text("DHCP"),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ntpTestView(),
          const Icon(
            Icons.directions_car,
          ),
          const Icon(
            Icons.ac_unit,
          ),
          const Icon(
            Icons.baby_changing_station,
          ),
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
