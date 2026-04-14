import 'dart:io';
import 'package:flutter/material.dart';
import 'package:regexed_validator/regexed_validator.dart';
import 'package:twsnmpfm/node.dart';
import 'package:twsnmpfm/l10n/app_localizations.dart';
import 'package:basic_utils/basic_utils.dart';

class NodeEditPage extends StatelessWidget {
  final Node node;
  const NodeEditPage({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(loc.editNode),
        ),
        body: NodeEditForm(node: node));
  }
}

class NodeEditForm extends StatefulWidget {
  final Node node;
  const NodeEditForm({super.key, required this.node});

  @override
  NodeEditFormState createState() {
    return NodeEditFormState();
  }
}

class NodeEditFormState extends State<NodeEditForm> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  String _errorMsg = '';

  void _getIPFromName() async {
    if (!mounted) return;
    setState(() {
      _errorMsg = "";
    });
    final name = widget.node.name.trim().replaceAll('　', '');
    if (name.isEmpty) {
      return;
    }
    try {
      // 1. Try system DNS lookup
      var ips = await InternetAddress.lookup(name);
      var ip = ips.first.address;
      _updateIP(ip);
    } catch (e) {
      try {
        // 2. Fallback to Google DNS lookup for emulator environments
        final records = await DnsUtils.lookupRecord(name, RRecordType.A);
        if (records != null && records.isNotEmpty) {
          _updateIP(records.first.data);
          return;
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
      });
    }
  }

  void _updateIP(String ip) {
    if (!mounted) return;
    setState(() {
      widget.node.ip = ip;
      _ipController.text = ip;
    });
  }

  @override
  void initState() {
    _ipController.text = widget.node.ip;
    super.initState();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(_errorMsg, style: const TextStyle(color: Colors.red)),
        Row(
          children: [
            widget.node.getIcon(),
            const SizedBox(width: 20),
            DropdownButton<String>(
                value: widget.node.icon,
                items: [
                  DropdownMenuItem(value: "laptop", child: Text(loc.laptop)),
                  DropdownMenuItem(value: "desktop", child: Text(loc.desktop)),
                  DropdownMenuItem(value: "lan", child: Text(loc.lan)),
                  DropdownMenuItem(value: "cloud", child: Text(loc.cloud)),
                  DropdownMenuItem(value: "server", child: Text(loc.server)),
                ],
                onChanged: (value) => {
                      setState(() {
                        widget.node.icon = value!;
                      })
                    }),
          ],
        ),
        TextFormField(
          initialValue: widget.node.name,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return loc.nameError;
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _errorMsg = '';
              widget.node.name = value;
            });
          },
          decoration: InputDecoration(icon: const Icon(Icons.edit), labelText: loc.nodeName, hintText: loc.nameHint),
        ),
        ElevatedButton.icon(
          icon: const Icon(
            Icons.search,
            color: Colors.white,
          ),
          onPressed: () {
            _getIPFromName();
          },
          label: Text(loc.getIPFromName),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
          ),
        ),
        TextFormField(
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          controller: _ipController,
          validator: (value) {
            if (value == null || value.isEmpty || !validator.ip(value)) {
              return loc.ipError;
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              widget.node.ip = value;
            });
          },
          decoration: InputDecoration(icon: const Icon(Icons.lan), labelText: loc.ip, hintText: loc.ipHint),
        ),
        TextFormField(
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.text,
          initialValue: widget.node.community,
          validator: (value) {
            if (value == null) {
              return loc.communityError;
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _errorMsg = '';
              widget.node.community = value;
            });
          },
          decoration: InputDecoration(icon: const Icon(Icons.security), labelText: loc.community, hintText: loc.communityHint),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context, widget.node);
              }
            },
            label: Text(loc.save),
          ),
        )
      ]),
    );
  }
}
