import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twsnmpfm/node.dart';

final nodeListCountProvider = StateProvider((ref) => 0);

class NodeListPage extends ConsumerWidget {
  const NodeListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.read(nodesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('TWSNMP For Mobile')),
      body: Consumer(builder: (context, ref, _) {
        ref.watch(nodeListCountProvider.state).state;
        return Scrollbar(
          child: ListView(
            restorationId: 'node_list_view',
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (int i = 0; i < nodes.nodes.length; i++)
                ListTile(
                  leading: getIcon(nodes.nodes[i].icon),
                  title: Text(nodes.nodes[i].name),
                  subtitle: Text(nodes.nodes[i].ip),
                  trailing: const Icon(Icons.more_vert),
                ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {addNode(ref)},
        child: const Icon(Icons.add),
      ),
    );
  }

  Icon getIcon(icon) {
    switch (icon) {
      case 'laptop':
        return const Icon(Icons.laptop);
      case 'desktop':
        return const Icon(Icons.desktop_windows);
      case 'server':
        return const Icon(Icons.dns);
      case 'cloud':
        return const Icon(Icons.cloud);
    }
    return const Icon(Icons.lan);
  }

  void addNode(WidgetRef ref) {
    final List<String> icons = ["laptop", "dektop", "server", "cloud", "lan"];
    final nodes = ref.read(nodesProvider);
    ref.read(nodeListCountProvider.state).state++;
    final ip = ref.read(nodeListCountProvider.state).state;
    nodes.add(Node(ip: '10.30.1.$ip', name: "node-$ip", icon: icons[ip % 5]));
    print(ip);
  }
}
