String enumValueName(Object value) {
  final text = value.toString();
  final dotIndex = text.indexOf('.');
  return dotIndex == -1 ? text : text.substring(dotIndex + 1);
}

T enumFromName<T>(List<T> values, String rawName) {
  return values.firstWhere((value) => enumValueName(value as Object) == rawName);
}
