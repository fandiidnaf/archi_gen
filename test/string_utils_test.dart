import 'package:archi_gen/archi_gen.dart';
import 'package:test/test.dart';

void main() {
  group('toPascalCase', () {
    test('converts snake_case', () {
      expect(toPascalCase('user_management'), 'UserManagement');
      expect(toPascalCase('auth'), 'Auth');
      expect(toPascalCase('sales_orders'), 'SalesOrders');
      expect(toPascalCase('product'), 'Product');
    });

    test('handles already PascalCase', () {
      expect(toPascalCase('UserManagement'), 'UserManagement');
    });
  });

  group('toSnakeCase', () {
    test('converts PascalCase', () {
      expect(toSnakeCase('UserManagement'), 'user_management');
      expect(toSnakeCase('Auth'), 'auth');
    });

    test('passes through existing snake_case', () {
      expect(toSnakeCase('user_management'), 'user_management');
    });
  });

  group('toCamelCase', () {
    test('converts snake_case to camelCase', () {
      expect(toCamelCase('user_management'), 'userManagement');
      expect(toCamelCase('auth'), 'auth');
    });
  });

  group('toTitleCase', () {
    test('converts to title case', () {
      expect(toTitleCase('user_management'), 'User Management');
      expect(toTitleCase('auth'), 'Auth');
    });
  });
}
