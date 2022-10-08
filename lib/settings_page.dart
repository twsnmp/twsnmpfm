import 'package:flutter/material.dart';
import 'package:twsnmpfm/settings.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  final Settings settings;
  const SettingsPage({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(
          title: Text(loc.settings),
        ),
        body: SettingsForm(settings: settings));
  }
}

class SettingsForm extends StatefulWidget {
  final Settings settings;
  const SettingsForm({super.key, required this.settings});

  @override
  SettingsFormState createState() {
    return SettingsFormState();
  }
}

class SettingsFormState extends State<SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  double _count = 5;
  double _timeout = 5;
  double _retry = 1;
  double _ttl = 5;
  double _interval = 5;
  String _mibName = "";
  bool _showAllPort = false;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    _count = widget.settings.count.toDouble();
    _timeout = widget.settings.timeout.toDouble();
    _retry = widget.settings.retry.toDouble();
    _interval = widget.settings.interval.toDouble();
    _ttl = widget.settings.ttl.toDouble();
    _mibName = widget.settings.mibName;
    _showAllPort = widget.settings.showAllPort;
    _themeMode = widget.settings.themeMode;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(child: Text("${loc.count}(${_count.toInt()})")),
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
              Expanded(child: Text("${loc.timeout}(${_timeout.toInt()}${loc.sec})")),
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
              Expanded(child: Text("${loc.retry}(${_retry.toInt()})")),
              Slider(
                  label: "${_retry.toInt()}",
                  value: _retry,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  onChanged: (value) => {
                        setState(() {
                          _retry = value;
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
          Row(
            children: [
              Expanded(child: Text("${loc.interval}(${_interval.toInt()}${loc.sec})")),
              Slider(
                  label: "${_interval.toInt()}",
                  value: _interval,
                  min: 5,
                  max: 60,
                  divisions: (60 - 5) ~/ 5,
                  onChanged: (value) => {
                        setState(() {
                          _interval = value;
                        })
                      }),
            ],
          ),
          TextFormField(
            initialValue: widget.settings.mibName,
            validator: (value) {
              if (value == null) {
                return "Null";
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _mibName = value;
              });
            },
            decoration: InputDecoration(labelText: loc.mibName, hintText: loc.mibName),
          ),
          Row(
            children: [
              Expanded(child: Text(loc.showAllPort)),
              Switch(
                value: _showAllPort,
                onChanged: (bool value) {
                  setState(() {
                    _showAllPort = value;
                  });
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text(loc.themeMode)),
              DropdownButton<ThemeMode>(
                  value: _themeMode,
                  items: [
                    DropdownMenuItem(value: ThemeMode.system, child: Text(loc.themeModeSystem)),
                    DropdownMenuItem(value: ThemeMode.light, child: Text(loc.themeModeLight)),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text(loc.themeModeDark)),
                  ],
                  onChanged: (value) => {
                        setState(() {
                          _themeMode = value!;
                        })
                      }),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.settings.count = _count.toInt();
                  widget.settings.timeout = _timeout.toInt();
                  widget.settings.retry = _retry.toInt();
                  widget.settings.interval = _interval.toInt();
                  widget.settings.ttl = _ttl.toInt();
                  widget.settings.mibName = _mibName;
                  widget.settings.showAllPort = _showAllPort;
                  widget.settings.themeMode = _themeMode;
                  Navigator.pop(context, widget.settings);
                }
              },
              child: Text(loc.save),
            ),
          ),
        ],
      ),
    );
  }
}
