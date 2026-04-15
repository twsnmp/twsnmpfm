import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:twsnmpfm/main.dart';
import 'package:twsnmpfm/node_list_page.dart';

void main() {
  testWidgets('App loads NodeListPage smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NodeListPage), findsOneWidget);
  });
}
