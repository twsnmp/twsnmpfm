import 'dart:typed_data';

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
import 'package:dart_snmp/dart_snmp.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  double _ntpTimeout = 2;
  String _errorMsg = '';
  String _lastResult = '';
  bool _process = false;

  String _target = "";

  // for NTP Test
  String _ntpTarget = '';
  final List<String> _ntpTargetList = [];
  final List<DataRow> _ntpStats = [];
  final List<num> _ntpOffset = [];
  final List<TimeSeriesNTPOffset> _ntpChartData = [];
  Timer? _timer;

  // for Syslog Test
  int _syslogFacility = 16; // local0
  int _syslogSeverity = 6; // info
  int _syslogFormat = 0; // BSD
  String _syslogMsg = "twsnmpfm: syslogtest";
  String _syslogHost = "twsnmpfm";
  final List<DataRow> _syslogHist = [];

  // for SNMP TRAP Test
  MIBDB? _mibdb;
  String _trapOID = "coldStart";
  String _trapCommunity = "trap";
  final List<String> _trapOIDs = ["coldStart", "warmStart", "linkUp", "linkDown", "authenticationFailure"];
  final List<DataRow> _trapHist = [];
  int _startTime = 0;

  // for DHCP Test
  int _dhcpPort = 67; // Server 67/Client 68
  UDP? _dhcpUDP;
  final List<DataRow> _dhcpHist = [];

  // for Mail Test
  String _mailUser = "";
  String _mailPassword = "";
  String _mailFrom = "";
  String _mailTo = "";
  String _mailSubject = "Mail from TWSNMP For Mobile";
  String _mailBody = "Mail from TWSNMP For Mobile";
  final List<DataRow> _mailHist = [];

  _ServerTestState() {
    _loadMIBDB();
  }

  @override
  void initState() {
    _ntpTarget = widget.node.ip;
    _ntpTargetList.add(_ntpTarget);
    _ntpTargetList.add(widget.node.name);
    _ntpTargetList.add("time.windows.com");
    _ntpTargetList.add("ntp.nict.jp");
    _ntpTargetList.add("time.asia.apple.com");
    _ntpTargetList.add("ntp.jst.mfeed.ad.jp");
    _ntpTargetList.add("time.cloudflare.com");
    _target = widget.node.ip;
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _load();
    _tabController = TabController(vsync: this, length: 5);
    _tabController?.addListener(() {
      _stop();
    });
    super.initState();
  }

  void _load() async {
    if (Platform.operatingSystem == 'macos') {
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // NTP
    _ntpTimeout = prefs.getDouble("ntpTimeout") ?? widget.settings.timeout.toDouble();
    // syslog
    _syslogFacility = prefs.getInt("syslogFacility") ?? 0;
    _syslogSeverity = prefs.getInt("syslogSeverity") ?? 6;
    _syslogFormat = prefs.getInt("syslogFormat") ?? 0;
    _syslogHost = prefs.getString("syslogHost") ?? Platform.localHostname;
    _syslogMsg = prefs.getString("syslogMsg") ?? "tag: from TWSNMP FM";
    // Trap
    _trapCommunity = prefs.getString("trapCommunity") ?? "trap";
    _trapOID = prefs.getString("trapOID") ?? "coldStart";
    // DHCP
    // Mail
    _mailUser = prefs.getString("mailUser") ?? "";
    _mailPassword = "";
    _mailFrom = prefs.getString("mailFrom") ?? "";
    _mailTo = prefs.getString("mailTo") ?? "";
    _mailSubject = prefs.getString("mailSubject") ?? "Mail From TWSNMP FM";
    _mailBody = prefs.getString("mailBody") ?? "Mail From TWSNMP FM";
  }

  void _save() async {
    if (Platform.operatingSystem == 'macos') {
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // NTP
    await prefs.setDouble('ntpTimeout', _ntpTimeout);
    // syslog
    await prefs.setInt('syslogFacility', _syslogFacility);
    await prefs.setInt('syslogSeverity', _syslogSeverity);
    await prefs.setInt('syslogFormat', _syslogFormat);
    await prefs.setString('syslogHost', _syslogHost);
    await prefs.setString('syslogMsg', _syslogMsg);
    // trap
    await prefs.setString('trapCommunity', _trapCommunity);
    await prefs.setString('trapOID', _trapOID);
    // DHCP
    // Mail
    await prefs.setString('mailUser', _mailUser);
    await prefs.setString('mailFrom', _mailFrom);
    await prefs.setString('mailTo', _mailTo);
    await prefs.setString('mailSubject', _mailSubject);
    await prefs.setString('mailBody', _mailBody);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _timer?.cancel();
    _save();
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
                  Expanded(child: Text("${loc!.timeout}(${_ntpTimeout.toInt()}${loc!.sec})")),
                  Slider(
                      label: "${_ntpTimeout.toInt()}",
                      value: _ntpTimeout,
                      min: 1,
                      max: 10,
                      divisions: (10 - 1),
                      onChanged: (value) => {
                            setState(() {
                              _ntpTimeout = value;
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
                columns: [
                  DataColumn(
                    label: Text(loc!.key),
                  ),
                  DataColumn(
                    label: Text(loc!.value),
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
                initialValue: _target,
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
                    _target = value;
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
                        DropdownMenuItem(value: 1, child: Text("RFC5424(IETF)")),
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
                        label: Text(loc?.time ?? "Time"),
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

  SingleChildScrollView _trapTestView() => SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                initialValue: _target,
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
                    _target = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.lan), labelText: loc?.server, hintText: loc?.server),
              ),
              TextFormField(
                initialValue: _trapCommunity,
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
                    _trapCommunity = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.password), labelText: loc?.community, hintText: loc?.community),
              ),
              Text(loc?.trapOID ?? "Trap OID", style: const TextStyle(fontSize: 12)),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _trapOID),
                optionsBuilder: (value) {
                  if (value.text.isEmpty) {
                    return [];
                  }
                  return _trapOIDs.where((n) => n.toLowerCase().contains(value.text.toLowerCase()));
                },
                onSelected: (value) {
                  setState(() {
                    _trapOID = value;
                  });
                },
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
                        label: Text(loc?.time ?? "Time"),
                      ),
                      DataColumn(
                        label: Text(loc?.length ?? "Length"),
                      ),
                      DataColumn(
                        label: Text(loc?.trapOID ?? "SNMP Trap OID"),
                      ),
                    ],
                    rows: _trapHist,
                  )),
            ],
          ),
        ),
      );

  SingleChildScrollView _dhcpTestView() => SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                children: [
                  Expanded(child: Text(loc?.dhcpPort ?? "DHCP Port")),
                  DropdownButton<int>(
                      value: _dhcpPort,
                      items: const [
                        DropdownMenuItem(value: 67, child: Text("Server(67)")),
                        DropdownMenuItem(value: 68, child: Text("Client(68)")),
                      ],
                      onChanged: (int? value) {
                        if (value == null || value == _dhcpPort) {
                          return;
                        }
                        setState(() {
                          _dhcpPort = value;
                          if (_process) {
                            _stop();
                            _start();
                          }
                        });
                      }),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  _sendDhcpDiscover();
                },
                child: const Text("Send Discover"),
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
                        label: Text(loc?.time ?? "Time"),
                      ),
                      DataColumn(
                        label: Text(loc?.dhcpAddress ?? "Address"),
                      ),
                      DataColumn(
                        label: Text(loc?.dhcpType ?? "Type"),
                      ),
                    ],
                    rows: _dhcpHist,
                  )),
            ],
          ),
        ),
      );

  SingleChildScrollView _mailTestView() => SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                initialValue: _target,
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
                    _target = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.lan), labelText: loc?.server, hintText: loc?.server),
              ),
              TextFormField(
                initialValue: _mailUser,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (value) {
                  setState(() {
                    _mailUser = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.account_circle), labelText: loc?.user, hintText: loc?.user),
              ),
              TextFormField(
                initialValue: _mailPassword,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (value) {
                  setState(() {
                    _mailPassword = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.password), labelText: loc?.password, hintText: loc?.password),
              ),
              TextFormField(
                initialValue: _mailFrom,
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
                    _mailFrom = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.person), labelText: loc?.mailFrom, hintText: loc?.mailFrom),
              ),
              TextFormField(
                initialValue: _mailTo,
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
                    _mailTo = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.person), labelText: loc?.mailTo, hintText: loc?.mailTo),
              ),
              TextFormField(
                initialValue: _mailSubject,
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
                    _mailSubject = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.subject), labelText: loc?.mailSubject, hintText: loc?.mailSubject),
              ),
              TextFormField(
                initialValue: _mailBody,
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
                    _mailBody = value;
                  });
                },
                decoration: InputDecoration(icon: const Icon(Icons.email), labelText: loc?.mailBody, hintText: loc?.mailBody),
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
                        label: Text(loc?.time ?? "Time"),
                      ),
                      DataColumn(
                        label: Text(loc?.mailSubject ?? "Subject"),
                      ),
                      DataColumn(
                        label: Text(loc?.status ?? "Status"),
                      ),
                    ],
                    rows: _mailHist,
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
      final int offset = await NTP.getNtpOffset(localTime: DateTime.now(), lookUpAddress: _ntpTarget, timeout: Duration(seconds: _ntpTimeout.toInt()));
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
      String ip = _target;
      if (_target.contains(":")) {
        final a = _target.split(":");
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
            DataCell(Text(DateFormat("HH:mm:ss").format(DateTime.now()))),
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

  void _sendTrap() async {
    setState(() {
      _errorMsg = "";
      _process = true;
    });
    try {
      final List<Varbind> vbl = [];
      vbl.add(Varbind(Oid.fromString(_mibdb!.nameToOid("sysUpTime.0")), VarbindType.TimeTicks, (DateTime.now().microsecondsSinceEpoch - _startTime) ~/ 10));
      vbl.add(Varbind(Oid.fromString(_mibdb!.nameToOid("snmpTrapOID")), VarbindType.Oid, _mibdb!.nameToOid(_trapOID)));
      vbl.add(Varbind(Oid.fromString(_mibdb!.nameToOid("snmpTrapEnterprise")), VarbindType.Oid, _mibdb!.nameToOid("enterprises.17861")));
      if (_trapOID.startsWith("link")) {
        vbl.add(Varbind(Oid.fromString(_mibdb!.nameToOid("ifIndex.1")), VarbindType.Integer, 1));
      }
      var p = Pdu(PduType.TrapV2, DateTime.now().millisecondsSinceEpoch, vbl);
      var m = Message(SnmpVersion.V2c, _trapCommunity, p);
      int port = 162;
      String ip = _target;
      if (_target.contains(":")) {
        final a = _target.split(":");
        if (a.length == 2) {
          ip = a[0];
          port = a[1].toInt();
        }
      }
      var sender = await UDP.bind(Endpoint.any());
      final len = await sender.send(m.encodedBytes, Endpoint.unicast(InternetAddress(ip), port: Port(port)));
      setState(() {
        _trapHist.add(
          DataRow(cells: [
            DataCell(Text(DateFormat("HH:mm:ss").format(DateTime.now()))),
            DataCell(Text(len.toString())),
            DataCell(Text(_trapOID)),
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

  void _dhcpTest() async {
    setState(() {
      _errorMsg = "";
      _process = true;
    });
    try {
      _dhcpUDP = await UDP.bind(Endpoint.any(port: Port(_dhcpPort)));
      if (_dhcpUDP == null) {
        return;
      }
      _dhcpUDP!.asStream().listen((datagram) {
        if (datagram == null) {
          return;
        }
        setState(() {
          _dhcpHist.add(
            DataRow(cells: [
              DataCell(Text(DateFormat("HH:mm:ss").format(DateTime.now()))),
              DataCell(Text(datagram.address.address)),
              DataCell(Text(_getDHCPType(datagram.data))),
            ]),
          );
        });
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _process = false;
      });
      _dhcpUDP?.close();
    }
  }

  void _sendDhcpDiscover() async {
    if (_dhcpUDP == null) {
      return;
    }
    await _dhcpUDP!.send(_makeDHCPPkt(), Endpoint.broadcast(port: const Port(67)));
  }

  List<int> _makeDHCPPkt() {
    List<int> r = [];
    r.add(0x01); // BOOTP Request
    r.add(0x01); // HW Type Ethernet
    r.add(0x06); // HW Addr len 6
    r.add(0x00);
    r.add(0x00); // XID
    r.add(0x01);
    r.add(0x02);
    r.add(0x03);

    r.add(0x00); // Sec
    r.add(0x00);

    r.add(0x80); // Flag Bcast
    r.add(0x00);

    r.add(0x00); // Client IP
    r.add(0x00);
    r.add(0x00);
    r.add(0x00);

    r.add(0x00); // Your IP
    r.add(0x00);
    r.add(0x00);
    r.add(0x00);

    r.add(0x00); // Next IP
    r.add(0x00);
    r.add(0x00);
    r.add(0x00);

    r.add(0x00); // Relay IP
    r.add(0x00);
    r.add(0x00);
    r.add(0x00);

    r.add(0x5d); //MAC Address
    r.add(0x01);
    r.add(0x02);
    r.add(0x03);
    r.add(0x04);
    r.add(0x05);
    // Padding
    for (var i = 0; i < 10; i++) {
      r.add(0x00);
    }
    // Server host name
    for (var i = 0; i < 16 * 4; i++) {
      r.add(0x00);
    }
    // Boot File Name
    for (var i = 0; i < 16 * 8; i++) {
      r.add(0x00);
    }
    // Magic
    r.add(0x63);
    r.add(0x82);
    r.add(0x53);
    r.add(0x63);
    // Discover
    r.add(0x35);
    r.add(0x01);
    r.add(0x01);
    // End
    r.add(0xff);
    return r;
  }

  String _getDHCPType(Uint8List data) {
    for (var i = 0; i < data.length - 7; i++) {
      if (data[i] == 0x63 && data[i + 1] == 0x82 && data[i + 2] == 0x53 && data[i + 3] == 0x63 && data[i + 4] == 0x35 && data[i + 5] == 0x01) {
        final mac = sprintf("%02x:%02x:%02x:%02x:%02x:%02x", [data[28], data[29], data[30], data[31], data[32], data[33]]);
        switch (data[i + 6]) {
          case 0x01:
            return "Discover($mac)";
          case 0x02:
            return "Offer";
          case 0x03:
            return "Request";
          case 0x04:
            return "Ack";
        }
      }
    }
    return "Unknow";
  }

  void _sendMail() async {
    setState(() {
      _errorMsg = "";
      _process = true;
    });
    try {
      int port = 25;
      String ip = _target;
      if (_target.contains(":")) {
        final a = _target.split(":");
        if (a.length == 2) {
          ip = a[0];
          port = a[1].toInt();
        }
      }
      SmtpServer? server;
      if (_mailUser != "" && _mailPassword != "") {
        server = SmtpServer(ip, port: port, username: _mailUser, password: _mailPassword, allowInsecure: true, ignoreBadCertificate: true);
      } else {
        server = SmtpServer(ip, port: port, allowInsecure: true, ignoreBadCertificate: true);
      }
      final message = mailer.Message()
        ..from = _mailFrom
        ..recipients.add(_mailTo)
        ..subject = _mailSubject
        ..text = _mailBody;
      final sendReport = await mailer.send(message, server);
      setState(() {
        _mailHist.add(
          DataRow(cells: [
            DataCell(Text(DateFormat("HH:mm:ss").format(DateTime.now()))),
            DataCell(Text(_mailSubject)),
            DataCell(Text(sendReport.toString())),
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

  void _start() {
    final index = _tabController?.index ?? 0;
    switch (index) {
      case 0:
        // NTP Test
        _startNTPTest();
        break;
      case 1:
        // syslog Test
        _sendSyslog();
        break;
      case 2:
        // trap Test
        _sendTrap();
        break;
      case 3:
        // DHCP Test
        _dhcpTest();
        break;
      case 4:
        // Mail Test
        _sendMail();
        break;
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _dhcpUDP?.close();
    _dhcpUDP = null;
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
              child: Text("NTP", style: TextStyle(fontSize: 12)),
            ),
            Tab(
              child: Text(
                "syslog",
                style: TextStyle(fontSize: 12),
              ),
            ),
            Tab(
              child: Text("Trap", style: TextStyle(fontSize: 12)),
            ),
            Tab(
              child: Text("DHCP", style: TextStyle(fontSize: 12)),
            ),
            Tab(
              child: Text("Mail", style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ntpTestView(),
          _syslogTestView(),
          _trapTestView(),
          _dhcpTestView(),
          _mailTestView(),
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
