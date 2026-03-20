import '../generators/feature_generator.dart';
import '../utils/file_helper.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';

class FeatureCommand {
  Future<void> run({
    required String featureName,
    bool withUsecase = true,
    bool withDatasource = true,
    bool withForm = false,
  }) async {
    if (!FileHelper.isFlutterProject()) {
      CliLogger.error('No Flutter project found in current directory.');
      CliLogger.hint('Run this command from your Flutter project root.');
      return;
    }

    final snakeName = toSnakeCase(featureName);
    final className = toPascalCase(featureName);
    final projectName = FileHelper.getProjectName();

    CliLogger.section('Generating Feature: $className');
    if (!withUsecase) CliLogger.warn('  UseCase files skipped (--no-usecase)');
    if (!withDatasource) {
      CliLogger.warn('  Datasource skipped (--no-datasource)');
    }
    if (withForm) CliLogger.info('  Form page included (--with-form)');
    CliLogger.divider();

    final generator = FeatureGenerator(
      featureName: snakeName,
      className: className,
      projectName: projectName,
      withUsecase: withUsecase,
      withDatasource: withDatasource,
      withForm: withForm,
    );
    await generator.generate();

    CliLogger.divider();
    CliLogger.success('Feature "$className" generated!');
    print('');
    _printNextSteps(
      snakeName,
      className,
      withUsecase,
      withDatasource,
      withForm,
    );
  }

  void _printNextSteps(
    String snake,
    String cls,
    bool withUsecase,
    bool withDatasource,
    bool withForm,
  ) {
    // withUsecase=true  → Bloc({required this.get$cls})  → get$cls: sl()
    // withUsecase=false → Bloc({required this.repository}) → repository: sl()
    final blocCtorParam = withUsecase ? 'get$cls: sl()' : 'repository: sl()';
    final repoCtorArg = withDatasource ? 'remoteDatasource: sl()' : '';
    final datasourceLine = withDatasource
        ? '\n    ..registerLazySingleton(() => ${cls}RemoteDatasourceImpl(dio: sl()))'
        : '';
    final usecaseLine = withUsecase
        ? '\n    ..registerLazySingleton(() => Get${cls}UseCase(sl()))'
        : '';

    CliLogger.hint('1. Register in lib/core/di/service_locator.dart:');
    print('''
  void _register$cls() {
    sl
      ..registerFactory(() => ${cls}Bloc($blocCtorParam))$usecaseLine
      ..registerLazySingleton<${cls}Repository>(
          () => ${cls}RepositoryImpl($repoCtorArg))$datasourceLine;
  }
''');

    CliLogger.hint(
      '2. Add route in lib/core/router/app_router.dart (inside StatefulShellBranch):',
    );
    print('''
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: ${cls}Page.route.path,
        name: ${cls}Page.route.name,
        builder: (context, state) => BlocProvider(
          create: (_) => sl<${cls}Bloc>(),
          child: const ${cls}Page(),
        ),
      ),${withForm ? '''
      GoRoute(
        path: '\${${cls}Page.route.path}/new',
        name: '${snake}_create',
        builder: (_, __) => const ${cls}FormPage(),
      ),''' : ''}
    ],
  ),
''');

    CliLogger.hint(
      '3. Add tab in lib/core/widgets/shell/main_shell.dart → _items:',
    );
    print('''
  _NavItem(
    label: '${toTitleCase(snake)}',
    icon: Icons.list_alt_outlined,
    activeIcon: Icons.list_alt,
  ),
''');
  }
}
