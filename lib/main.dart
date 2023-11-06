import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twsnmpfm/node_list_page.dart';
import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:twsnmpfm/settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPingIOS.register();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'TWSNMP FM',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: settings.themeMode,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('ja', ''), // 日本語, no country code
      ],
      home: const NodeListPage(),
    );
  }
}
