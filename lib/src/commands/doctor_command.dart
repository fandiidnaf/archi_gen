import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';
import '../utils/logger.dart';

class DoctorCommand {
  int _passCount = 0;
  int _warnCount = 0;
  int _failCount = 0;

  Future<void> run() async {
    CliLogger.printBanner();
    print('');

    if (!FileHelper.isFlutterProject()) {
      CliLogger.error('Not inside a Flutter project.');
      return;
    }

    CliLogger.section('Doctor — ${FileHelper.getProjectName()}');
    print('');

    await _checkCore();
    await _checkDependencies();
    await _checkFeatures();
    await _checkRouter();

    print('');
    CliLogger.divider();
    _printSummary();
  }

  Future<void> _checkCore() async {
    CliLogger.section('Core Structure');

    final checks = {
      'lib/core/errors/failures.dart': 'Failure types',
      'lib/core/usecases/usecase.dart': 'UseCase base',
      'lib/core/constants/app_constants.dart': 'AppConstants',
      'lib/core/extensions/num_ext.dart': 'num extensions (.h/.w)',
      // Network
      'lib/core/network/dio_client.dart': 'DioClient',
      'lib/core/network/token_storage.dart': 'AppTokenStorage (OAuth2Token)',
      'lib/core/network/interceptors/auth_interceptor.dart':
          'AuthInterceptor (fresh_dio)',
      'lib/core/network/interceptors/error_interceptor.dart':
          'ErrorInterceptor',
      'lib/core/network/interceptors/logging_interceptor.dart':
          'LoggingInterceptor',
      // DI + Router
      'lib/core/di/service_locator.dart': 'GetIt service locator',
      'lib/core/router/app_router.dart': 'AppRouter (StatefulShellRoute)',
      'lib/core/router/route_structure.dart': 'RouteStructure',
      // Theme
      'lib/core/theme/app_colors.dart': 'AppColors',
      'lib/core/theme/app_theme.dart': 'AppTheme',
      'lib/core/theme/app_typography.dart': 'AppTypography',
      // Utils + Mixins
      'lib/core/utils/app_logger.dart': 'AppLogger',
      'lib/core/utils/formatters.dart': 'Formatters',
      'lib/core/utils/paginated_result.dart': 'PaginatedResult<T>',
      'lib/core/utils/responsive.dart': 'Responsive',
      'lib/core/mixins/helper_mixin.dart': 'HelperMixin',
      // Widgets
      'lib/core/widgets/common/app_card.dart': 'AppCard',
      'lib/core/widgets/common/app_data_table.dart': 'AppDataTable',
      'lib/core/widgets/common/confirm_dialog.dart': 'ConfirmDialog',
      'lib/core/widgets/common/empty_state.dart': 'EmptyState',
      'lib/core/widgets/common/loading_widget.dart': 'LoadingWidget',
      'lib/core/widgets/common/permission_guard.dart': 'PermissionGuard',
      'lib/core/widgets/common/search_filter_bar.dart': 'SearchFilterBar',
      'lib/core/widgets/common/status_badge.dart': 'StatusBadge',
      'lib/core/widgets/shell/main_shell.dart': 'MainShell',
      'lib/main.dart': 'main.dart',
    };

    for (final e in checks.entries) {
      _checkFile(p.join(FileHelper.cwd, e.key), e.value);
    }
  }

  Future<void> _checkDependencies() async {
    CliLogger.section('Dependencies (pubspec.yaml)');

    final pubspecPath = p.join(FileHelper.cwd, 'pubspec.yaml');
    if (!File(pubspecPath).existsSync()) {
      _fail('pubspec.yaml not found!');
      return;
    }

    final content = File(pubspecPath).readAsStringSync();

    final required = {
      'dio': '^5.x',
      'equatable': '^2.x',
      'flutter_bloc': '^8.x',
      'flutter_secure_storage': '^9.x',
      'fpdart': '^1.x',
      'fresh_dio': '^0.5.1',
      'get_it': '^8.x',
      'go_router': '^14.x',
      'google_fonts': '^6.x',
      'intl': '^0.19.x',
      'pretty_dio_logger': '^3.x',
    };

    for (final e in required.entries) {
      if (content.contains('${e.key}:')) {
        _pass(e.key);
      } else {
        _fail('${e.key} missing — run: flutter pub add ${e.key}');
      }
    }
  }

  Future<void> _checkFeatures() async {
    final featuresDir = Directory(FileHelper.libPath(['features']));
    if (!featuresDir.existsSync()) {
      CliLogger.section('Features');
      _warn('No features yet — run: dart run clean_arch_gen feature <n>');
      return;
    }

    final features = featuresDir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList()
      ..sort();

    if (features.isEmpty) {
      CliLogger.section('Features');
      _warn('features/ folder exists but is empty.');
      return;
    }

    CliLogger.section('Features (${features.length})');
    for (final name in features) {
      final dir = Directory(FileHelper.libPath(['features', name]));
      _checkFeatureIntegrity(name, dir);
    }
  }

  void _checkFeatureIntegrity(String name, Directory dir) {
    final critical = [
      p.join(dir.path, 'domain', 'entities', '${name}_entity.dart'),
      p.join(dir.path, 'domain', 'repositories', '${name}_repository.dart'),
      p.join(dir.path, 'data', 'repositories', '${name}_repository_impl.dart'),
      p.join(dir.path, 'presentation', 'bloc', '${name}_bloc.dart'),
      p.join(dir.path, 'presentation', 'pages', '${name}_page.dart'),
    ];
    final missing = critical.where((f) => !File(f).existsSync()).toList();
    if (missing.isEmpty) {
      _pass('feature/$name — all critical files present');
    } else {
      _warn('feature/$name — missing: ${missing.map(p.basename).join(', ')}');
    }
  }

  Future<void> _checkRouter() async {
    CliLogger.section('Route Registration');

    final routerFile =
        File(FileHelper.libPath(['core', 'router', 'app_router.dart']));
    if (!routerFile.existsSync()) {
      _warn('app_router.dart not found — run: dart run clean_arch_gen init');
      return;
    }

    final routerContent = routerFile.readAsStringSync();
    final featuresDir = Directory(FileHelper.libPath(['features']));
    if (!featuresDir.existsSync()) return;

    for (final d in featuresDir.listSync().whereType<Directory>()) {
      final feature = p.basename(d.path);
      final cls = _toPascal(feature);
      final hasPath = routerContent.contains("'/$feature") ||
          routerContent.contains('"/$feature');
      final hasRoute = routerContent.contains('${cls}Page.route');
      if (hasPath || hasRoute) {
        _pass('$feature route registered');
      } else {
        _warn('$feature — not found in app_router.dart');
      }
    }
  }

  void _checkFile(String path, String label) {
    if (File(path).existsSync()) {
      _pass(label);
    } else {
      _fail('$label — missing: ${p.relative(path, from: FileHelper.cwd)}');
    }
  }

  void _pass(String msg) {
    _passCount++;
    print('  \x1B[32m  ✓  $msg\x1B[0m');
  }

  void _warn(String msg) {
    _warnCount++;
    print('  \x1B[33m  ⚠  $msg\x1B[0m');
  }

  void _fail(String msg) {
    _failCount++;
    print('  \x1B[31m  ✗  $msg\x1B[0m');
  }

  void _printSummary() {
    final total = _passCount + _warnCount + _failCount;
    if (_failCount == 0 && _warnCount == 0) {
      CliLogger.success('All checks passed ($total/$total) 🎉');
      return;
    }
    print(
      '  Results: '
      '\x1B[32m$_passCount passed\x1B[0m  '
      '\x1B[33m$_warnCount warnings\x1B[0m  '
      '\x1B[31m$_failCount failed\x1B[0m  '
      'out of $total',
    );
    if (_failCount > 0) {
      print('');
      CliLogger.hint('Fix core:  dart run clean_arch_gen init');
      CliLogger.hint('Fix deps:  flutter pub add <package>');
    }
  }

  String _toPascal(String snake) => snake
      .split('_')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join('');
}
