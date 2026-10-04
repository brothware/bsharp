List<Map<String, dynamic>> objectsOf(Object? data, String view) {
  if (data is! List) {
    throw FormatException('View $view: expected a list', data);
  }
  return data.map((item) {
    if (item is! Map<String, dynamic>) {
      throw FormatException('View $view: expected objects', item);
    }
    return item;
  }).toList();
}

int intField(Map<String, dynamic> json, String key, String view) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('View $view: "$key" is not an int', json);
  }
  return value;
}

String stringField(Map<String, dynamic> json, String key, String view) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('View $view: "$key" is not a string', json);
  }
  return value;
}

String? optionalStringField(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : null;
}
