import 'package:flutter/material.dart';
import 'package:regexed_validator/regexed_validator.dart';
import 'package:twsnmpfm/node.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return loc.nameError;
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                widget.node.name = value;
              });
            },
            decoration: InputDecoration(icon: const Icon(Icons.edit), labelText: loc.nodeName, hintText: loc.nameHint),
          ),
          TextFormField(
            initialValue: widget.node.ip,
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
            initialValue: widget.node.community,
            validator: (value) {
              if (value == null) {
                return loc.communityError;
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                widget.node.community = value;
              });
            },
            decoration: InputDecoration(icon: const Icon(Icons.security), labelText: loc.community, hintText: loc.communityHint),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context, widget.node);
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
