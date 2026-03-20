import '../generators/preset_generator.dart';
import '../utils/file_helper.dart';
import '../utils/logger.dart';

class PresetCommand {
  Future<void> run({required String presetName, bool force = false}) async {
    if (!FileHelper.isFlutterProject()) {
      CliLogger.error('No Flutter project found in current directory.');
      return;
    }

    final projectName = FileHelper.getProjectName();

    switch (presetName.toLowerCase()) {
      case 'auth':
        CliLogger.section('Generating Preset: Auth');
        CliLogger.divider();
        await PresetGenerator.auth(force: force);
        CliLogger.divider();
        CliLogger.success('Auth preset generated!');
        print('');
        _printAuthHints();

      case 'dashboard':
        CliLogger.section('Generating Preset: Dashboard');
        CliLogger.divider();
        await PresetGenerator.dashboard(projectName: projectName, force: force);
        CliLogger.divider();
        CliLogger.success('Dashboard preset generated!');
        print('');
        _printDashboardHints();

      default:
        CliLogger.error('Unknown preset: "$presetName"');
        CliLogger.hint('Available presets: auth, dashboard');
    }
  }

  void _printAuthHints() {
    CliLogger.hint('1. Register in lib/core/di/service_locator.dart:');
    print(r'''
  void _registerAuth() {
    sl
      ..registerFactory(() => AuthBloc(
            signIn: sl(), signOut: sl(), getCurrentProfile: sl(),
          ))
      ..registerLazySingleton(() => SignInUseCase(sl()))
      ..registerLazySingleton(() => SignOutUseCase(sl()))
      ..registerLazySingleton(() => GetCurrentProfileUseCase(sl()))
      ..registerLazySingleton<AuthRepository>(
          () => AuthRepositoryImpl(remoteDatasource: sl()))
      ..registerLazySingleton(
          () => AuthRemoteDatasourceImpl(dio: sl()));
  }
''');

    CliLogger.hint(
      '2. Add routes in app_router.dart (outside StatefulShellRoute):',
    );
    print(r'''
  GoRoute(
    path: LoginPage.route.path,
    name: LoginPage.route.name,
    builder: (_, __) => BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AppStarted()),
      child: const LoginPage(),
    ),
  ),
''');

    CliLogger.hint('3. Add Auth guard to AppRouter.router:');
    print(r'''
  // redirect: (context, state) {
  //   final isLoggedIn = sl<AuthBloc>().state is AuthAuthenticated;
  //   final isGoingToLogin = state.matchedLocation == LoginPage.route.path;
  //   if (!isLoggedIn && !isGoingToLogin) return LoginPage.route.path;
  //   if (isLoggedIn && isGoingToLogin) return '/home';
  //   return null;
  // },
''');

    CliLogger.hint('4. Add AuthBloc as global provider in main.dart:');
    print(r'''
   BlocProvider(
    create: (_) => sl<AuthBloc>()..add(const AppStarted()),
    child: MaterialApp.router(...),
  );
''');

    CliLogger.hint('5. API endpoints expected by AuthRemoteDatasourceImpl:');
    print('''
  POST /auth/login    → { access_token, refresh_token, user: {...} }
  POST /auth/logout   → 200 OK
  GET  /auth/me       → { id, email, full_name, role, avatar_url, created_at }
  POST /auth/refresh  → { access_token, refresh_token, user: {...} }
''');
  }

  void _printDashboardHints() {
    CliLogger.hint('1. Register in lib/core/di/service_locator.dart:');
    print(r'''
  void _registerDashboard() {
    sl
      ..registerFactory(() => DashboardBloc(datasource: sl()))
      ..registerLazySingleton(() => DashboardDatasourceImpl(dio: sl()));
  }
''');
    CliLogger.hint(
      '2. Add route in app_router.dart (first branch, path: \'/home\'):',
    );
    print(r'''
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<DashboardBloc>()..add(const DashboardLoad()),
          child: const DashboardPage(),
        ),
      ),
    ],
  ),
''');
    CliLogger.hint('3. API endpoints expected by DashboardDatasourceImpl:');
    print('''
  GET /dashboard/stats → { total_orders, total_revenue, active_customers,
                           pending_items, revenue_chart: [...], recent_activity: [...] }
''');
  }
}
