import 'package:test/test.dart';
import 'package:twsnmpfm/mibdb.dart';
import 'dart:io';

void main() {
  final mibfile = File('./assets/conf/mib.txt').readAsStringSync();
  final mibdb = MIBDB(mibfile);
  test('MIBDB Test oidToName', () {
    Map<String, String> testData = {
      "1.3.6.1.2.1.1.1": "sysDescr",
      "1.3.6.1.2.1.1.2": "sysObjectID",
      "1.3.6.1.2.1.1.1.0": "sysDescr.0",
      "1.3.6.1.2.1.1.5": "sysName",
    };
    testData.forEach((key, value) {
      final name = mibdb.oidToName(key);
      expect(name, value);
    });
  });

  test('MIBDB Test nameToOid', () {
    Map<String, String> testData = {
      "sysDescr": "1.3.6.1.2.1.1.1",
      "sysObjectID": "1.3.6.1.2.1.1.2",
      "sysDescr.0": "1.3.6.1.2.1.1.1.0",
      "sysName": "1.3.6.1.2.1.1.5",
    };
    testData.forEach((key, value) {
      final oid = mibdb.nameToOid(key);
      expect(oid, value);
    });
  });

  test('MIBDB Test unknown OID', () {
    // 1.3.6 is likely 'dod' in the mib.txt
    expect(mibdb.oidToName("1.3.6.999.1.1"), "dod.999.1.1");
    // unknown name returns 0.0
    expect(mibdb.nameToOid("unknownMibName"), "0.0");
  });
}
