/// Converts snake_case or camelCase to PascalCase
/// e.g. "user_management" → "UserManagement"
/// e.g. "auth" → "Auth"
String toPascalCase(String input) {
  // Handle already PascalCase
  if (!input.contains('_') && input[0] == input[0].toUpperCase()) {
    return input;
  }
  return input
      .split('_')
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join('');
}

/// Converts PascalCase or camelCase to snake_case
/// e.g. "UserManagement" → "user_management"
/// e.g. "auth" → "auth"
String toSnakeCase(String input) {
  // If already snake_case, return as-is
  if (input.contains('_')) return input.toLowerCase();
  return input
      .replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
      .replaceFirst(RegExp(r'^_'), '');
}

/// Converts snake_case to camelCase
/// e.g. "user_management" → "userManagement"
String toCamelCase(String input) {
  final pascal = toPascalCase(input);
  if (pascal.isEmpty) return pascal;
  return pascal[0].toLowerCase() + pascal.substring(1);
}

/// e.g. "user_management" → "User Management"
String toTitleCase(String input) {
  return toSnakeCase(input)
      .split('_')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
