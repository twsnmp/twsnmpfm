import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/mibdb.dart';
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
import 'package:fl_chart/fl_chart.dart';
import 'package:twsnmpfm/time_line_chart.dart';

class ServerTestPage extends StatefulWidget {
  final Node node;
  final Settings settings;
  const ServerTestPage({super.key, required this.node, required this.settings});

  @override
  State<ServerTestPage> createState() => _ServerTestState();
}

class _ServerTestState extends State<ServerTestPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  AppLocalizations? loc;
  bool _process = false;

  String _target = "";

  // for NTP Test
  double _ntpTimeout = 2;
  String _ntpTarget = '';
  String _errorMsgNTP = '';
  String _lastResultNTP = '';
  final List<String> _ntpTargetList = [];
  final List<DataRow> _ntpStats = [];
  final List<num> _ntpOffset = [];
  final List<TimeLineSeries> _ntpChartData = [];
  Timer? _timer;

  // for Syslog Test
  int _syslogFacility = 16; // local0
  int _syslogSeverity = 6; // info
  int _syslogFormat = 0; // BSD
  String _syslogMsg = "tag: from TWSNMP FM";
  String _syslogHost = "twsnmpfm.local";
  String _errorMsgSyslog = '';
  final List<DataRow> _syslogHist = [];

  // for SNMP TRAP Test
  MIBDB? _mibdb;
  String _trapOID = "coldStart";
  String _trapCommunity = "trap";
  String _errorMsgTrap = '';
  final List<String> _trapOIDs = ["coldStart", "warmStart", "linkUp", "linkDown", "authenticationFailure"];
  final List<DataRow> _trapHist = [];
  int _startTime = 0;

  // for Mail Test
  String _mailUser = "";
  String _mailPassword = "";
  String _mailFrom = "";
  String _mailTo = "";
  String _mailSubject = "Mail from TWSNMP For Mobile";
  String _mailBody = "Mail from TWSNMP For Mobile";
  String _errorMsgMail = '';
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
    _tabController = TabController(vsync: this, length: Platform.isIOS ? 5 : 4);
    _tabController?.addListener(() {
      _stop();
    });
    super.initState();
    _load();
  }

  void _load() async {
    if (Platform.operatingSystem == 'macos') {
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
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
    });
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

  SingleChildScrollView _ntpTestView(bool dark) => SingleChildScrollView(
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
                _lastResultNTP,
                style: TextStyle(fontSize: 16, color: dark ? Colors.white : Colors.black87),
              ),
              Text(
                _errorMsgNTP,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
              SizedBox(
                height: 180,
                child: TimeLineChart(_createNTPChartData()),
              ),
              DataTable(
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
                rows: _ntpStats,
              ),
            ],
          ),
        ),
      );

  SingleChildScrollView _syslogTestView(bool dark) => SingleChildScrollView(
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
                children: [
                  const Expanded(child: Text("PRI:")),
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
                ],
              ),
              Row(children: [
                const Expanded(child: Text("Format:")),
                DropdownButton<int>(
                    value: _syslogFormat,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text("BSD")),
                      DropdownMenuItem(value: 1, child: Text("RFC5424(IETF)")),
                      DropdownMenuItem(value: 2, child: Text("BSD(ISO Time)")),
                    ],
                    onChanged: (int? value) {
                      setState(() {
                        _syslogFormat = value ?? 0;
                      });
                    })
              ]),
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
                _errorMsgSyslog,
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

  SingleChildScrollView _trapTestView(bool dark) => SingleChildScrollView(
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
                _errorMsgTrap,
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

  SingleChildScrollView _mailTestView(bool dark) => SingleChildScrollView(
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
                keyboardType: TextInputType.emailAddress,
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
                keyboardType: TextInputType.emailAddress,
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
                _errorMsgMail,
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

  List<LineChartBarData> _createNTPChartData() {
    final List<FlSpot> spots = [];
    for (var i = 0; i < _ntpChartData.length; i++) {
      spots.add(FlSpot(_ntpChartData[i].time, _ntpChartData[i].value[0]));
    }
    return [
      LineChartBarData(
        spots: spots,
      )
    ];
  }

  void _startNTPTest() {
    if (_timer != null) {
      return;
    }
    setState(() {
      _lastResultNTP = "";
      _errorMsgNTP = "";
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
        _errorMsgNTP = "";
      });
      final int offset = await NTP.getNtpOffset(localTime: DateTime.now(), lookUpAddress: _ntpTarget, timeout: Duration(seconds: _ntpTimeout.toInt()));
      setState(() {
        _lastResultNTP = "offset $offset mSec";
        _ntpChartData.add(TimeLineSeries(DateTime.now().millisecondsSinceEpoch.toDouble(), [offset.toDouble()]));
        _ntpOffset.add(offset);
        _setNTPStats();
      });
      if (_ntpOffset.length > 100) {
        _stop();
      }
    } catch (e) {
      setState(() {
        _errorMsgNTP = e.toString();
      });
      _stop();
    }
  }

  void _sendSyslog() async {
    setState(() {
      _errorMsgSyslog = "";
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
        _errorMsgSyslog = e.toString();
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
      _errorMsgTrap = "";
      _process = true;
    });
    try {
      final List<Varbind> vbl = [];
      vbl.add(Varbind(Oid.fromString(_mibdb!.nameToOid("sysUpTime.0")), const VarbindType.fromInt(TIME_TICKS), (DateTime.now().microsecondsSinceEpoch - _startTime) ~/ 10));
      vbl.add(Varbind(Oid.fromString(_mibdb!.nameToOid("snmpTrapOID")), const VarbindType.fromInt(OID), _mibdb!.nameToOid(_trapOID)));
      vbl.add(Varbind(Oid.fromString(_mibdb!.nameToOid("snmpTrapEnterprise")), const VarbindType.fromInt(OID), _mibdb!.nameToOid("enterprises.17861")));
      if (_trapOID.startsWith("link")) {
        vbl.add(Varbind(Oid.fromString(_mibdb!.nameToOid("ifIndex.1")), const VarbindType.fromInt(INTEGER), 1));
      }
      var p = Pdu(PduType.trapV2, DateTime.now().millisecondsSinceEpoch, vbl);
      var m = Message(SnmpVersion.v2c, _trapCommunity, p);
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
        _errorMsgTrap = e.toString();
      });
    } finally {
      setState(() {
        _process = false;
      });
    }
  }

  void _sendMail() async {
    setState(() {
      _errorMsgMail = "";
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
        _errorMsgMail = e.toString();
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
        // Mail Test
        _sendMail();
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
    bool dark = Theme.of(context).brightness == Brightness.dark;
    loc = AppLocalizations.of(context)!;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text("${loc!.serverTest} ${widget.node.name}"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              child: Text("NTP", style: TextStyle(fontSize: 12)),
            ),
            const Tab(
              child: Text(
                "syslog",
                style: TextStyle(fontSize: 10),
              ),
            ),
            const Tab(
              child: Text("Trap", style: TextStyle(fontSize: 12)),
            ),
            const Tab(
              child: Text("Mail", style: TextStyle(fontSize: 12)),
            ),
            if (Platform.isIOS) const Tab(child: Text("DHCP", style: TextStyle(fontSize: 12))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ntpTestView(dark),
          _syslogTestView(dark),
          _trapTestView(dark),
          _mailTestView(dark),
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
