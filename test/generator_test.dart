import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:clean_arch_gen/clean_arch_gen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cag_test_');
    await File(p.join(tempDir.path, 'pubspec.yaml')).writeAsString(
      'name: test_app\nflutter:\n  uses-material-design: true\n',
    );
    await Directory(p.join(tempDir.path, 'lib')).create();
    Directory.current = tempDir;
  });

  tearDown(() async {
    Directory.current = Directory.systemTemp;
    await tempDir.delete(recursive: true);
  });

  // ─── CoreGenerator ────────────────────────────────────────────────────────

  group('CoreGenerator', () {
    test('generates all expected files including network layer', () async {
      await CoreGenerator(projectName: 'test_app').generate();

      final expected = [
        // Errors + Usecases
        'lib/core/errors/failures.dart',
        'lib/core/usecases/usecase.dart',
        // Constants + Extensions
        'lib/core/constants/app_constants.dart',
        'lib/core/extensions/num_ext.dart',
        // Network
        'lib/core/network/dio_client.dart',
        'lib/core/network/token_storage.dart',
        'lib/core/network/interceptors/auth_interceptor.dart',
        'lib/core/network/interceptors/error_interceptor.dart',
        'lib/core/network/interceptors/logging_interceptor.dart',
        // DI + Router
        'lib/core/di/service_locator.dart',
        'lib/core/router/app_router.dart',
        'lib/core/router/route_structure.dart',
        // Theme
        'lib/core/theme/app_colors.dart',
        'lib/core/theme/app_typography.dart',
        'lib/core/theme/app_theme.dart',
        // Utils + Mixins
        'lib/core/utils/app_logger.dart',
        'lib/core/utils/formatters.dart',
        'lib/core/utils/responsive.dart',
        'lib/core/utils/paginated_result.dart',
        'lib/core/mixins/helper_mixin.dart',
        // Widgets
        'lib/core/widgets/common/loading_widget.dart',
        'lib/core/widgets/common/app_card.dart',
        'lib/core/widgets/common/status_badge.dart',
        'lib/core/widgets/common/search_filter_bar.dart',
        'lib/core/widgets/common/app_data_table.dart',
        'lib/core/widgets/common/permission_guard.dart',
        'lib/core/widgets/common/empty_state.dart',
        'lib/core/widgets/common/confirm_dialog.dart',
        'lib/core/widgets/shell/main_shell.dart',
        // Entry point
        'lib/main.dart',
      ];

      for (final path in expected) {
        final file = File(p.join(tempDir.path, path));
        expect(file.existsSync(), isTrue, reason: 'Missing: $path');
        expect(file.readAsStringSync().isNotEmpty, isTrue, reason: '$path empty');
      }
    });

    test('service_locator uses GetIt.instance (not broken)', () async {
      await CoreGenerator(projectName: 'test_app').generate();
      final content = File(p.join(tempDir.path, 'lib/core/di/service_locator.dart'))
          .readAsStringSync();
      expect(content, contains('GetIt.instance'));
      expect(content, isNot(contains('= .instance')));
    });

    test('service_locator registers DioClient, AuthInterceptor, SharedPreferences', () async {
      await CoreGenerator(projectName: 'test_app').generate();
      final content = File(p.join(tempDir.path, 'lib/core/di/service_locator.dart'))
          .readAsStringSync();
      expect(content, contains('DioClient.create'));
      expect(content, contains('AuthInterceptor'));
      expect(content, contains('SharedPreferences'));
      expect(content, contains('configureDependencies() async'));
    });

    test('main() is async and awaits configureDependencies', () async {
      await CoreGenerator(projectName: 'test_app').generate();
      final content = File(p.join(tempDir.path, 'lib/main.dart')).readAsStringSync();
      expect(content, contains('void main() async'));
      expect(content, contains('await configureDependencies()'));
    });

    test('auth_interceptor uses Fresh.oAuth2 and RevokeTokenException', () async {
      await CoreGenerator(projectName: 'test_app').generate();
      final content = File(p.join(
        tempDir.path,
        'lib/core/network/interceptors/auth_interceptor.dart',
      )).readAsStringSync();
      expect(content, contains('Fresh.oAuth2'));
      expect(content, contains('RevokeTokenException'));
      expect(content, contains('shouldRefresh'));
    });

    test('error_interceptor maps all major status codes', () async {
      await CoreGenerator(projectName: 'test_app').generate();
      final content = File(p.join(
        tempDir.path,
        'lib/core/network/interceptors/error_interceptor.dart',
      )).readAsStringSync();
      expect(content, contains('401'));
      expect(content, contains('404'));
      expect(content, contains('422'));
      expect(content, contains('>= 500'));
      expect(content, contains('toFailure'));
    });

    test('token_storage implements TokenStorage<AppToken>', () async {
      await CoreGenerator(projectName: 'test_app').generate();
      final content = File(p.join(
        tempDir.path,
        'lib/core/network/token_storage.dart',
      )).readAsStringSync();
      expect(content, contains('implements TokenStorage<AppToken>'));
      expect(content, contains('implements Token'));
      expect(content, contains('SharedPreferences'));
    });

    test('dio_client uses kDebugMode for logger', () async {
      await CoreGenerator(projectName: 'test_app').generate();
      final content = File(p.join(
        tempDir.path,
        'lib/core/network/dio_client.dart',
      )).readAsStringSync();
      expect(content, contains('kDebugMode'));
      expect(content, contains('ErrorInterceptor'));
      expect(content, contains('AuthInterceptor'));
    });

    test('app_router uses StatefulShellRoute.indexedStack', () async {
      await CoreGenerator(projectName: 'test_app').generate();
      final content = File(p.join(tempDir.path, 'lib/core/router/app_router.dart'))
          .readAsStringSync();
      expect(content, contains('StatefulShellRoute.indexedStack'));
      expect(content, contains('StatefulShellBranch'));
    });

    test('route_structure.dart defines RouteStructure', () async {
      await CoreGenerator(projectName: 'test_app').generate();
      final content = File(p.join(tempDir.path, 'lib/core/router/route_structure.dart'))
          .readAsStringSync();
      expect(content, contains('class RouteStructure'));
      expect(content, contains('final String path'));
      expect(content, contains('final String name'));
    });

    test('app_theme imports app_typography and uses AppTypography', () async {
      await CoreGenerator(projectName: 'test_app').generate();
      final content = File(p.join(tempDir.path, 'lib/core/theme/app_theme.dart'))
          .readAsStringSync();
      expect(content, contains("import 'app_typography.dart'"));
      expect(content, contains('AppTypography'));
    });

    test('num_ext defines .h and .w', () async {
      await CoreGenerator(projectName: 'test_app').generate();
      final content = File(p.join(tempDir.path, 'lib/core/extensions/num_ext.dart'))
          .readAsStringSync();
      expect(content, contains('get h'));
      expect(content, contains('get w'));
    });

    test('main_shell uses StatefulNavigationShell and goBranch', () async {
      await CoreGenerator(projectName: 'test_app').generate();
      final content = File(p.join(
        tempDir.path, 'lib/core/widgets/shell/main_shell.dart',
      )).readAsStringSync();
      expect(content, contains('StatefulNavigationShell'));
      expect(content, contains('goBranch'));
    });

    test('does not overwrite files without force', () async {
      final mainPath = p.join(tempDir.path, 'lib', 'main.dart');
      await File(mainPath).writeAsString('// SENTINEL');
      await CoreGenerator(projectName: 'test_app').generate();
      expect(File(mainPath).readAsStringSync(), contains('// SENTINEL'));
    });

    test('overwrites when force=true', () async {
      final mainPath = p.join(tempDir.path, 'lib', 'main.dart');
      await File(mainPath).writeAsString('// SENTINEL');
      await CoreGenerator(projectName: 'test_app', force: true).generate();
      expect(File(mainPath).readAsStringSync(), isNot(contains('// SENTINEL')));
    });
  });

  // ─── FeatureGenerator ─────────────────────────────────────────────────────

  group('FeatureGenerator — defaults', () {
    test('generates all 10 files', () async {
      await FeatureGenerator(
        featureName: 'product', className: 'Product', projectName: 'test_app',
      ).generate();

      for (final path in _productFiles) {
        expect(File(p.join(tempDir.path, path)).existsSync(), isTrue,
            reason: 'Missing: $path');
      }
    });

    test('datasource uses Dio (not Supabase)', () async {
      await FeatureGenerator(
        featureName: 'product', className: 'Product', projectName: 'test_app',
      ).generate();
      final content = File(p.join(
        tempDir.path,
        'lib/features/product/data/datasources/product_remote_datasource.dart',
      )).readAsStringSync();
      expect(content, contains('Dio'));
      expect(content, isNot(contains('Supabase')));
    });

    test('page has static RouteStructure route', () async {
      await FeatureGenerator(
        featureName: 'product', className: 'Product', projectName: 'test_app',
      ).generate();
      final content = File(p.join(
        tempDir.path,
        'lib/features/product/presentation/pages/product_page.dart',
      )).readAsStringSync();
      expect(content, contains('static const RouteStructure route'));
    });

    test('repository_impl catches DioException', () async {
      await FeatureGenerator(
        featureName: 'product', className: 'Product', projectName: 'test_app',
      ).generate();
      final content = File(p.join(
        tempDir.path,
        'lib/features/product/data/repositories/product_repository_impl.dart',
      )).readAsStringSync();
      expect(content, contains('DioException'));
    });
  });

  group('FeatureGenerator — flags', () {
    test('--no-usecase: skips usecase file', () async {
      await FeatureGenerator(
        featureName: 'product', className: 'Product',
        projectName: 'test_app', withUsecase: false,
      ).generate();
      expect(
        File(p.join(tempDir.path,
            'lib/features/product/domain/usecases/get_product_usecase.dart'))
            .existsSync(),
        isFalse,
      );
    });

    test('--no-datasource: skips datasource file', () async {
      await FeatureGenerator(
        featureName: 'product', className: 'Product',
        projectName: 'test_app', withDatasource: false,
      ).generate();
      expect(
        File(p.join(tempDir.path,
            'lib/features/product/data/datasources/product_remote_datasource.dart'))
            .existsSync(),
        isFalse,
      );
    });

    test('--with-form: generates form page', () async {
      await FeatureGenerator(
        featureName: 'product', className: 'Product',
        projectName: 'test_app', withForm: true,
      ).generate();
      final f = File(p.join(tempDir.path,
          'lib/features/product/presentation/pages/product_form_page.dart'));
      expect(f.existsSync(), isTrue);
      expect(f.readAsStringSync(), contains('ProductFormPage'));
    });
  });
}

const _productFiles = [
  'lib/features/product/domain/entities/product_entity.dart',
  'lib/features/product/domain/repositories/product_repository.dart',
  'lib/features/product/domain/usecases/get_product_usecase.dart',
  'lib/features/product/data/models/product_model.dart',
  'lib/features/product/data/datasources/product_remote_datasource.dart',
  'lib/features/product/data/repositories/product_repository_impl.dart',
  'lib/features/product/presentation/bloc/product_event.dart',
  'lib/features/product/presentation/bloc/product_state.dart',
  'lib/features/product/presentation/bloc/product_bloc.dart',
  'lib/features/product/presentation/pages/product_page.dart',
];
