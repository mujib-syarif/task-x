/// Helper konversi aman untuk data yang datang dari MethodChannel.
Map<String, dynamic> asMap(Object? o) {
  if (o is Map) {
    return o.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(Object? o) {
  if (o is List) {
    return o.map(asMap).toList();
  }
  return <Map<String, dynamic>>[];
}

int? asInt(Object? o) => o is num ? o.toInt() : null;

double? asDouble(Object? o) => o is num ? o.toDouble() : null;

String? asString(Object? o) => o?.toString();

List<int?> asNullableIntList(Object? o) {
  if (o is List) {
    return o.map(asInt).toList();
  }
  return <int?>[];
}
