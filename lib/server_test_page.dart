import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'package:twsnmpfm/ntp_chart.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/services.dart' show rootBundle;
import 'package:twsnmpfm/settings.dart';
import 'package:statistics/statistics.dart';
import 'dart:async';
import 'package:ntp/ntp.dart';
import 'package:sprintf/sprintf.dart';
import 'package:udp/udp.dart';
import 'dart:io';

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
  String _errorMsg = '';
  String _lastResult = '';
  bool _process = false;
  MIBDB? _mibdb;
  // for NTP Test
  String _ntpTarget = '';
  final List<String> _ntpTargetList = [];
  final List<DataRow> _ntpStats = [];
  final List<num> _ntpOffset = [];
  final List<TimeSeriesNTPOffset> _ntpChartData = [];
  Timer? _timer;

  // for Syslog Test
  String _syslogDst = "";
  int _syslogFacility = 16; // local0
  int _syslogSeverity = 6; // info
  int _syslogFormat = 0; // BSD
  String _syslogMsg = "twsnmpfm: syslogtest";
  String _syslogHost = "twsnmpfm";
  final List<DataRow> _syslogHist = [];

  _ServerTestState() {
    _loadMIBDB();
  }

  @override
  void initState() {
    _timeout = widget.settings.timeout.toDouble();
    _ntpTarget = widget.node.ip;
    _syslogDst = widget.node.ip;
    _ntpTargetList.add(_ntpTarget);
    _ntpTargetList.add(widget.node.name);
    _ntpTargetList.add("time.windows.com");
    _ntpTargetList.add("ntp.nict.jp");
    _ntpTargetList.add("time.asia.apple.com");
    _ntpTargetList.add("ntp.jst.mfeed.ad.jp");
    _ntpTargetList.add("time.cloudflare.com");
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
                initialValue: TextEditingValue(text: _ntpTarget),
                optionsBuilder: (value) {
                  if (value.text.isEmpty) {
                    return [];
                  }
                  _ntpTarget = value.text;
                  return _ntpTargetList.where((n) => n.toLowerCase().contains(value.text.toLowerCase()));
                },
                onSelected: (value) {
                  setState(() {
                    _ntpTarget = value;
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
  SingleChildScrollView _syslogTestView() => SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                initialValue: _syslogDst,
                autocorrect: false,
                enableSuggestions: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc?.requiredError;
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _syslogDst = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.lan), labelText: loc?.server, hintText: loc?.server),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DropdownButton<int>(
                      value: _syslogFacility,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text("kernel")),
                        DropdownMenuItem(value: 2, child: Text("mail")),
                        DropdownMenuItem(value: 3, child: Text("daemon")),
                        DropdownMenuItem(value: 10, child: Text("auth")),
                        DropdownMenuItem(value: 16, child: Text("local0")),
                        DropdownMenuItem(value: 17, child: Text("local1")),
                        DropdownMenuItem(value: 18, child: Text("local2")),
                      ],
                      onChanged: (int? value) {
                        setState(() {
                          _syslogFacility = value ?? 16;
                        });
                      }),
                  DropdownButton<int>(
                      value: _syslogSeverity,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text("emerg")),
                        DropdownMenuItem(value: 1, child: Text("alert")),
                        DropdownMenuItem(value: 2, child: Text("crit")),
                        DropdownMenuItem(value: 3, child: Text("err")),
                        DropdownMenuItem(value: 4, child: Text("warning")),
                        DropdownMenuItem(value: 5, child: Text("notice")),
                        DropdownMenuItem(value: 6, child: Text("info")),
                        DropdownMenuItem(value: 7, child: Text("debug")),
                      ],
                      onChanged: (int? value) {
                        setState(() {
                          _syslogSeverity = value ?? 6;
                        });
                      }),
                  DropdownButton<int>(
                      value: _syslogFormat,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text("BSD")),
                        DropdownMenuItem(value: 1, child: Text("IETF")),
                        DropdownMenuItem(value: 2, child: Text("TWSNMP FC")),
                      ],
                      onChanged: (int? value) {
                        setState(() {
                          _syslogFormat = value ?? 0;
                        });
                      }),
                ],
              ),
              TextFormField(
                initialValue: _syslogHost,
                autocorrect: false,
                enableSuggestions: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc?.requiredError;
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _syslogHost = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.lan), labelText: loc?.host, hintText: loc?.host),
              ),
              TextFormField(
                initialValue: _syslogMsg,
                autocorrect: false,
                enableSuggestions: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc?.requiredError;
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _syslogMsg = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.mail), labelText: loc?.syslogMsg, hintText: loc?.syslogMsg),
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
                        label: Text(loc?.timeStamp ?? "Time"),
                      ),
                      DataColumn(
                        label: Text(loc?.length ?? "Length"),
                      ),
                      DataColumn(
                        label: Text(loc?.syslogMsg ?? "Message"),
                      ),
                    ],
                    rows: _syslogHist,
                  )),
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
      final int offset = await NTP.getNtpOffset(localTime: DateTime.now(), lookUpAddress: _ntpTarget, timeout: Duration(seconds: _timeout.toInt()));
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

  void _sendSyslog() async {
    setState(() {
      _errorMsg = "";
      _process = true;
    });
    try {
      int port = 514;
      String ip = _syslogDst;
      if (_syslogDst.contains(":")) {
        final a = _syslogDst.split(":");
        if (a.length == 2) {
          ip = a[0];
          port = a[1].toInt();
        }
      }
      var sender = await UDP.bind(Endpoint.any());
      final msg = _getSyslogMsg();
      final len = await sender.send(msg.codeUnits, Endpoint.unicast(InternetAddress(ip), port: Port(port)));
      setState(() {
        _syslogHist.add(
          DataRow(cells: [
            DataCell(Text(DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()))),
            DataCell(Text(len.toString())),
            DataCell(Text(msg)),
          ]),
        );
      });
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

  String _getSyslogMsg() {
    final now = DateTime.now();
    var duration = now.timeZoneOffset;
    final tz = duration.isNegative
        ? ("-${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes - (duration.inHours * 60)).toString().padLeft(2, '0')}")
        : ("+${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes - (duration.inHours * 60)).toString().padLeft(2, '0')}");
    switch (_syslogFormat) {
      case 1:
        // IETF
        final ts = sprintf("%sT%s%s", [DateFormat("yyyy-MM-dd").format(now), DateFormat("HH:mm:ss").format(now), tz]);
        return sprintf("<%d>1 %s %s %s", [_syslogFacility * 8 + _syslogSeverity, ts, _syslogHost, _syslogMsg]);
      case 2:
        // TWSNMP FC
        final ts = sprintf("%sT%s%s", [DateFormat("yyyy-MM-dd").format(now), DateFormat("HH:mm:ss").format(now), tz]);
        return sprintf("<%d>%s %s %s", [_syslogFacility * 8 + _syslogSeverity, ts, _syslogHost, _syslogMsg]);
      default:
        // BSD
        final ts = DateFormat("MMM d  HH:mm:ss").format(now);
        return sprintf("<%d>%s %s %s", [_syslogFacility * 8 + _syslogSeverity, ts, _syslogHost, _syslogMsg]);
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
        _sendSyslog();
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
          _syslogTestView(),
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
