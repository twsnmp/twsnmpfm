import 'package:flutter/material.dart';
import 'package:statistics/statistics.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PingPage extends StatefulWidget {
  const PingPage({Key? key, required this.ip}) : super(key: key);

  final String ip;

  @override
  State<PingPage> createState() => _PingPageState();
}

class _PingPageState extends State<PingPage> {
  int _count = 5;
  int _timeout = 2;
  int _ttl = 255;
  int _maxTTL = 0;
  int _minTTL = 255;
  final List<DataRow> _stats = [];
  final List<num> _rtts = [];
  String _lastResult = "";
  Ping? ping;

  void _startPing(AppLocalizations loc) {
    int i = 0;
    _stats.length = 0;
    ping = Ping(widget.ip, count: _count, timeout: _timeout, ttl: _ttl);
    ping?.stream.listen((event) {
      final ttl = event.response?.ttl ?? '';
      setState(() {
        if (ttl != '') {
          final nrtt = event.response?.time?.inMicroseconds.toDouble() ?? 0.0;
          _rtts.add(nrtt / (1000 * 1000));
          final nttl = ttl.toString().toInt();
          if (nttl < _minTTL) {
            _minTTL = nttl;
          }
          if (nttl > _maxTTL) {
            _maxTTL = nttl;
          }
          i++;
          setState(() {
            _lastResult = '$i/$_count rtt=${nrtt / (1000 * 100)} ttl=$ttl';
            _setStats(loc);
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
            }
            _setStats(loc);
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

  void _setStats(AppLocalizations loc) {
    if (_rtts.isEmpty) {
      return;
    }
    _stats.length = 0;
    var statistics = _rtts.statistics;
    _stats.add(
      DataRow(cells: [
        DataCell(Text("${loc.max} TTL")),
        DataCell(Text("$_maxTTL")),
      ]),
    );
    _stats.add(
      DataRow(cells: [
        DataCell(Text("${loc.min} TTL")),
        DataCell(Text("$_minTTL")),
      ]),
    );
    _stats.add(
      DataRow(cells: [
        DataCell(Text("${loc.max} RTT(Sec)")),
        DataCell(Text(statistics.max.toStringAsFixed(6))),
      ]),
    );
    _stats.add(
      DataRow(cells: [
        DataCell(Text("${loc.min} RTT(Sec)")),
        DataCell(Text(statistics.min.toStringAsFixed(6))),
      ]),
    );
    _stats.add(
      DataRow(cells: [
        DataCell(Text("${loc.mean} RTT(Sec)")),
        DataCell(Text(statistics.mean.toStringAsFixed(6))),
      ]),
    );
    _stats.add(
      DataRow(cells: [
        DataCell(Text("${loc.median} RTT(Sec)")),
        DataCell(Text(statistics.median.toStringAsFixed(6))),
      ]),
    );
    _stats.add(
      DataRow(cells: [
        DataCell(Text(loc.sd)),
        DataCell(Text(statistics.standardDeviation.toStringAsFixed(6))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: Text("Ping ${widget.ip}"),
          ),
          body: SingleChildScrollView(
            child: Form(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(children: <Widget>[
                    Flexible(
                        child: TextFormField(
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      initialValue: '5',
                      onChanged: (value) {
                        if (value.isEmpty) {
                          return;
                        }
                        setState(() {
                          try {
                            _count = value.toInt();
                          } on FormatException catch (_) {
                            _count = 5;
                          }
                        });
                      },
                      decoration: InputDecoration(
                          labelText: loc.pingCount,
                          hintText: loc.pingCountHint),
                    )),
                    Flexible(
                        child: TextFormField(
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      initialValue: '2',
                      onChanged: (value) {
                        setState(() {
                          try {
                            _timeout = value.toInt();
                          } on FormatException catch (_) {
                            _timeout = 2;
                          }
                        });
                      },
                      decoration: InputDecoration(
                          labelText: loc.pingTimeout,
                          hintText: loc.pingTimeoutHint),
                    )),
                    Flexible(
                        child: TextFormField(
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      initialValue: '255',
                      onChanged: (value) {
                        setState(() {
                          try {
                            _ttl = value.toInt();
                          } on FormatException catch (_) {
                            _ttl = 255;
                          }
                        });
                      },
                      decoration: InputDecoration(
                          labelText: loc.pingTTL, hintText: loc.pingTTLHint),
                    ))
                  ]),
                  Text(
                    _lastResult,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  DataTable(
                    headingTextStyle: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 16,
                    ),
                    headingRowHeight: 22,
                    dataTextStyle:
                        const TextStyle(color: Colors.black, fontSize: 14),
                    dataRowHeight: 20,
                    columns: const [
                      DataColumn(
                        label: Text('項目'),
                      ),
                      DataColumn(
                        label: Text('値'),
                      ),
                    ],
                    rows: _stats,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ping == null
                        ? ElevatedButton(
                            onPressed: () {
                              _startPing(loc);
                            },
                            child: Text(loc.start),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Colors.red,
                            ),
                            onPressed: () {
                              _stopPing();
                            },
                            child: Text(loc.stop),
                          ),
                  )
                ],
              ),
            ),
          )),
    );
  }
}
