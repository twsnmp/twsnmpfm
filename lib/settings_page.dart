import 'package:flutter/material.dart';
import 'package:twsnmpfm/settings.dart';
import 'package:twsnmpfm/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  final Settings settings;
  const SettingsPage({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(
          title: Semantics(
              identifier: 'settings_app_bar_title', child: Text(loc.settings)),
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
  String _language = "system";
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
    _language = widget.settings.language;
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
              Semantics(
                identifier: 'settings_count_slider',
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
              Expanded(
                  child: Text("${loc.timeout}(${_timeout.toInt()}${loc.sec})")),
              Semantics(
                identifier: 'settings_timeout_slider',
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
              Expanded(child: Text("${loc.retry}(${_retry.toInt()})")),
              Semantics(
                identifier: 'settings_retry_slider',
                child: Slider(
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
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text("TTL(${_ttl.toInt()})")),
              Semantics(
                identifier: 'settings_ttl_slider',
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
              Expanded(
                  child: Text("${loc.interval}(${_interval.toInt()}${loc.sec})")),
              Semantics(
                identifier: 'settings_interval_slider',
                child: Slider(
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
              ),
            ],
          ),
          Semantics(
            identifier: 'settings_mib_name_input',
            child: TextFormField(
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
              decoration:
                  InputDecoration(labelText: loc.mibName, hintText: loc.mibName),
            ),
          ),
          Row(
            children: [
              Expanded(child: Text(loc.showAllPort)),
              Semantics(
                identifier: 'settings_show_all_port_switch',
                child: Switch(
                  value: _showAllPort,
                  onChanged: (bool value) {
                    setState(() {
                      _showAllPort = value;
                    });
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text(loc.themeMode)),
              Semantics(
                identifier: 'settings_theme_mode_dropdown',
                child: DropdownButton<ThemeMode>(
                    value: _themeMode,
                    items: [
                      DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Semantics(
                              container: true,
                              identifier: 'theme_mode_item_system',
                              child: Text(loc.themeModeSystem))),
                      DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Semantics(
                              container: true,
                              identifier: 'theme_mode_item_light',
                              child: Text(loc.themeModeLight))),
                      DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Semantics(
                              container: true,
                              identifier: 'theme_mode_item_dark',
                              child: Text(loc.themeModeDark))),
                    ],
                    onChanged: (value) => {
                          setState(() {
                            _themeMode = value!;
                          })
                        }),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text(loc.language)),
              Semantics(
                container: true,
                identifier: 'language_dropdown',
                child: DropdownButton<String>(
                    value: _language,
                    items: [
                      DropdownMenuItem(
                          value: "system",
                          child: Semantics(
                              container: true,
                              identifier: 'language_item_system',
                              child: Text(loc.languageSystem))),
                      DropdownMenuItem(
                          value: "en",
                          child: Semantics(
                              container: true,
                              identifier: 'language_item_en',
                              child: Text(loc.languageEnglish))),
                      DropdownMenuItem(
                          value: "ja",
                          child: Semantics(
                              container: true,
                              identifier: 'language_item_ja',
                              child: Text(loc.languageJapanese))),
                    ],
                    onChanged: (value) => {
                          setState(() {
                            _language = value!;
                          })
                        }),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Semantics(
              identifier: 'save_settings_button',
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.settings.count = _count.toInt();
                    widget.settings.timeout = _timeout.toInt();
                    widget.settings.retry = _retry.toInt();
                    widget.settings.interval = _interval.toInt();
                    widget.settings.ttl = _ttl.toInt();
                    widget.settings.mibName = _mibName;
                    widget.settings.language = _language;
                    widget.settings.showAllPort = _showAllPort;
                    widget.settings.themeMode = _themeMode;
                    Navigator.pop(context, widget.settings);
                  }
                },
                child: Text(loc.save),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
