class MIBDB {
  final Map<String, String> _nameToOid = {};
  final Map<String, String> _oidToName = {};
  MIBDB(String mibfile) {
    final list = mibfile.split("\n");
    for (var i = 0; i < list.length - 1; i += 2) {
      var oid = list[i].trim();
      var name = list[i + 1].trim();
      if (oid == "" || name == "") {
        continue;
      }
      if (oid[0] == ".") {
        oid = oid.substring(1);
      }
      if (name[0] == ".") {
        name = name.substring(1);
      }
      final na = name.split(".");
      if (na.isEmpty) {
        continue;
      }
      final sname = na[na.length - 1];
      if (_oidToName.containsKey(oid)) {
        continue;
      }
      if (_nameToOid.containsKey(sname)) {
        continue;
      }
      _nameToOid[sname] = oid;
      _oidToName[oid] = sname;
    }
  }
  String oidToName(String? oid) {
    oid ??= "";
    if (oid.isNotEmpty && oid[0] == '.') {
      oid = oid.substring(1);
    }
    if (_oidToName.containsKey(oid)) {
      return _oidToName[oid]!;
    }
    final a = oid.split(".");
    final List<String> suffix = [];
    while (a.isNotEmpty) {
      suffix.insert(0, a.removeLast());
      final o = a.join(".");
      if (_oidToName.containsKey(o)) {
        return "${_oidToName[o]!}.${suffix.join('.')}";
      }
    }
    return oid;
  }

  String nameToOid(String? name) {
    name ??= "";
    final a = name.split(".");
    if (a.isNotEmpty) {
      final n = a.removeAt(0);
      if (_nameToOid.containsKey(n)) {
        return a.isEmpty ? _nameToOid[n]! : "${_nameToOid[n]!}.${a.join('.')}";
      }
    }
    return "0.0";
  }

  List<String> getAllNames() {
    final List<String> names = [];
    for (var n in _nameToOid.keys) {
      names.add(n);
    }
    return names;
  }
}
