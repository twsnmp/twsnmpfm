import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twsnmpfm/node.dart';
import 'dart:io';
import 'package:twsnmpfm/settings.dart';
import 'package:basic_utils/basic_utils.dart';

class CertPage extends StatefulWidget {
  final Node node;
  final Settings settings;
  const CertPage({Key? key, required this.node, required this.settings}) : super(key: key);

  @override
  State<CertPage> createState() => _CertState();
}

class _CertState extends State<CertPage> {
  String _target = "";
  final List<String> _targetList = [];
  bool _process = false;
  String _errorMsg = '';
  List<Widget> listTiles = [];

  _CertState();

  @override
  void initState() {
    _target = widget.node.name;
    _targetList.add(_target);
    _targetList.add(widget.node.name);
    super.initState();
  }

  void _getCert(AppLocalizations loc) async {
    if (_process) {
      return;
    }
    setState(() {
      _process = true;
      _errorMsg = "";
    });
    try {
      bool bad = false;
      final a = _target.split(":");
      var p = "443";
      var ip = _target;
      if (a.length == 2) {
        p = a[1];
        ip = a[0];
      }
      var port = int.parse(p);
      if (port < 1) {
        port = 443;
      }
      final socket = await SecureSocket.connect(
        ip,
        port,
        onBadCertificate: (certificate) {
          bad = true;
          return true;
        },
      );
      setState(() {
        listTiles = [];
        if (socket.peerCertificate == null) {
          return;
        }
        if (!_targetList.contains(_target)) {
          _targetList.add(_target);
        }
        var data = X509Utils.x509CertificateFromPem(socket.peerCertificate!.pem);
        listTiles.add(ListTile(
          dense: true,
          leading: Icon(bad ? Icons.error : Icons.verified, color: bad ? Colors.red : Colors.blue),
          title: Text(loc.verify),
          subtitle: Text(bad ? "NG" : "OK"),
        ));
        listTiles.add(ListTile(
          dense: true,
          leading: const Icon(Icons.dns),
          title: Text(loc.subject),
          subtitle: Text(socket.peerCertificate!.subject),
        ));
        listTiles.add(ListTile(
          dense: true,
          leading: const Icon(Icons.verified_user),
          title: Text(loc.issuer),
          subtitle: Text(socket.peerCertificate!.issuer),
        ));
        listTiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.schedule, color: socket.peerCertificate!.startValidity.isAfter(DateTime.now()) ? Colors.red : Colors.blue),
          title: Text(loc.startValidity),
          subtitle: Text(socket.peerCertificate!.startValidity.toIso8601String()),
        ));
        listTiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.schedule, color: socket.peerCertificate!.endValidity.isBefore(DateTime.now()) ? Colors.red : Colors.blue),
          title: Text(loc.endValidity),
          subtitle: Text(socket.peerCertificate!.endValidity.toIso8601String()),
        ));
        var d = socket.peerCertificate!.endValidity.difference(socket.peerCertificate!.startValidity);
        var c = Colors.red;
        if (d.inDays < 399) {
          c = Colors.blue;
        } else if (d.inDays < 365 * 2) {
          c = Colors.amber;
        }
        listTiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.hourglass_top, color: c),
          title: Text(loc.certDur),
          subtitle: Text(d.inDays.toString()),
        ));
        listTiles.add(ListTile(
          dense: true,
          leading: const Icon(Icons.pin),
          title: Text(loc.version),
          subtitle: Text(data.version.toString()),
        ));
        listTiles.add(ListTile(
          dense: true,
          leading: const Icon(Icons.pin),
          title: Text(loc.serialNumber),
          subtitle: Text(data.serialNumber.toString()),
        ));
        listTiles.add(ListTile(
          dense: true,
          leading: const Icon(Icons.info),
          title: Text(loc.signatureAlgorithm),
          subtitle: Text(data.signatureAlgorithm),
        ));
        if (data.extensions != null) {
          listTiles.add(ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle),
            title: Text(loc.sha1Thumbprint),
            subtitle: Text(data.sha1Thumbprint ?? ""),
          ));
          listTiles.add(ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle),
            title: Text(loc.sha256Thumbprint),
            subtitle: Text(data.sha256Thumbprint ?? ""),
          ));
          var kalg = data.publicKeyData.algorithmReadableName ?? data.publicKeyData.algorithm.toString();
          listTiles.add(ListTile(
            dense: true,
            leading: const Icon(Icons.key),
            title: Text(loc.algorithmReadableName),
            subtitle: Text(kalg),
          ));
          c = Colors.grey;
          if (data.publicKeyData.length != null) {
            if (kalg.startsWith("ec")) {
              if (data.publicKeyData.length! < 256) {
                c = Colors.red;
              } else if (data.publicKeyData.length! < 512) {
                c = Colors.amber;
              } else {
                c = Colors.blue;
              }
            } else {
              if (data.publicKeyData.length! < 2048) {
                c = Colors.red;
              } else if (data.publicKeyData.length! < 4096) {
                c = Colors.amber;
              } else {
                c = Colors.blue;
              }
            }
          }
          listTiles.add(ListTile(
            dense: true,
            leading: Icon(Icons.key, color: c),
            title: Text(loc.keyLength),
            subtitle: Text(data.publicKeyData.length.toString()),
          ));
          listTiles.add(ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle),
            title: Text(loc.keySha1Thumbprint),
            subtitle: Text(data.publicKeyData.sha1Thumbprint ?? ""),
          ));
          listTiles.add(ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle),
            title: Text(loc.keySha256Thumbprint),
            subtitle: Text(data.publicKeyData.sha1Thumbprint ?? ""),
          ));
          if (data.extensions != null) {
            if (data.extensions!.subjectAlternativNames != null) {
              for (var sa in data.extensions!.subjectAlternativNames!) {
                listTiles.add(ListTile(
                  dense: true,
                  leading: const Icon(Icons.dns),
                  title: Text(loc.subjectAlternativNames),
                  subtitle: Text(sa),
                ));
              }
            }
            if (data.extensions!.cRLDistributionPoints != null) {
              for (var cdp in data.extensions!.cRLDistributionPoints!) {
                listTiles.add(ListTile(
                  dense: true,
                  leading: const Icon(Icons.public),
                  title: Text(loc.cRLDistributionPoints),
                  subtitle: Text(cdp),
                ));
              }
            }
          }
        }
        _process = false;
      });
      socket.close();
    } catch (e) {
      setState(() {
        listTiles = [];
        _errorMsg = e.toString();
        _process = false;
      });
    }
  }

  List<Widget> _getView(AppLocalizations loc) {
    List<Widget> r = [
      Text(loc.ipOrHostPort, style: const TextStyle(color: Colors.blue)),
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
      Text(_errorMsg, style: const TextStyle(color: Colors.red))
    ];
    for (var l in listTiles) {
      r.add(l);
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.cert),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _getView(loc),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _getCert(loc);
          },
          child: _process ? const Icon(Icons.stop, color: Colors.red) : const Icon(Icons.play_circle),
        ),
      ),
    );
  }
}
