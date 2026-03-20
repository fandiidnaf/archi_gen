class CoreTemplates {
  // ─── failures.dart ────────────────────────────────────────────────────────

  static String failures() => r'''
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;
  const ValidationFailure(super.message, {this.fieldErrors});

  @override
  List<Object?> get props => [message, fieldErrors];
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized access']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}
''';

  // ─── usecase.dart ─────────────────────────────────────────────────────────

  static String usecase() => r'''
import 'package:fpdart/fpdart.dart';
import '../errors/failures.dart';

abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

abstract class NoParamUseCase<T> {
  Future<Either<Failure, T>> call();
}

class NoParams {
  const NoParams();
}
''';

  // ─── app_constants.dart ───────────────────────────────────────────────────

  static String appConstants() => r'''
/// App-wide primitive constants.
///
/// Design system files (colors, typography, theme) live in core/theme/ —
/// they depend on Flutter. This file is for plain Dart primitives only.
abstract class AppConstants {
  AppConstants._();

  // ── API ───────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://api.yourapp.com/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout    = Duration(seconds: 15);

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;

  // ── Storage keys ─────────────────────────────────────────────────────────
  static const String tokenKey        = 'app_auth_token';
  static const String userIdKey       = 'user_id';
  static const String onboardedKey    = 'onboarded';
}
''';

  // ─── num_ext.dart ─────────────────────────────────────────────────────────

  static String numExt() => r'''
import 'package:flutter/material.dart';

/// SizedBox shorthand extensions on [num].
///
/// ```dart
/// 12.h   // SizedBox(height: 12)
/// 16.w   // SizedBox(width: 16)
/// ```
extension NumSpacingExt on num {
  SizedBox get h  => SizedBox(height: toDouble());
  SizedBox get w  => SizedBox(width: toDouble());
}
''';

  // ─── service_locator.dart ─────────────────────────────────────────────────

  static String serviceLocator(String projectName) => r'''
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/token_storage.dart';

final GetIt sl = GetIt.instance;

/// Call once in [main] before [runApp].
Future<void> configureDependencies() async {
  _registerCoreServices();

  // Register feature dependencies below:
  // _registerAuth();
  // _registerHome();
}

void _registerCoreServices() {
  // ── FlutterSecureStorage ───────────────────────────────────────────────────
  // Android: RSA OAEP + AES-GCM | iOS/macOS: Keychain
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => createSecureStorage(),
  );

  // ── Token storage ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<AppTokenStorage>(
    () => AppTokenStorage(sl()),
  );

  // ── Dio ────────────────────────────────────────────────────────────────────
  // DioClient.create() wires interceptors in the correct order:
  //   1. ErrorInterceptor    → DioException → AppException → Failure
  //   2. AuthInterceptor     → OAuth2Token attach + auto-refresh on 401
  //   3. PrettyDioLogger     → debug builds only
  sl.registerLazySingleton<Dio>(
    () => DioClient.create(tokenStorage: sl()),
  );

  // ── AuthInterceptor ────────────────────────────────────────────────────────
  // After login:
  //   sl<AuthInterceptor>().setToken(const OAuth2Token(accessToken: '...'));
  // On logout:
  //   sl<AuthInterceptor>().revokeToken();
  // Auth changes:
  //   sl<AuthInterceptor>().authenticationStatus.listen((s) { ... });
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(tokenStorage: sl(), dio: sl()),
  );
}

// ── Feature registrations ──────────────────────────────────────────────────
// Paste the snippet printed by `dart run archi_gen feature <n>` here.
//
// Example:
// void _registerHome() {
//   sl
//     ..registerFactory(() => HomeBloc(getHome: sl()))
//     ..registerLazySingleton(() => GetHomeUseCase(sl()))
//     ..registerLazySingleton<HomeRepository>(
//         () => HomeRepositoryImpl(remoteDatasource: sl()))
//     ..registerLazySingleton(() => HomeRemoteDatasourceImpl(dio: sl()));
// }
''';

  // ─── route_structure.dart ─────────────────────────────────────────────────

  static String routeStructure() => r'''
/// Type-safe route definition.
///
/// Add a static [route] to each Page:
/// ```dart
/// class ProductPage extends StatelessWidget {
///   static const RouteStructure route = RouteStructure(
///     path: '/products',
///     name: 'products',
///   );
/// }
/// ```
/// Then reference it in app_router.dart:
/// ```dart
/// GoRoute(
///   path: ProductPage.route.path,
///   name: ProductPage.route.name,
///   ...
/// )
/// ```
class RouteStructure {
  final String path;
  final String name;

  const RouteStructure({required this.path, required this.name});
}
''';

  // ─── app_router.dart ──────────────────────────────────────────────────────

  static String appRouter(String projectName) => r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/shell/main_shell.dart';

/// App router using [StatefulShellRoute.indexedStack].
///
/// Each [StatefulShellBranch] is a bottom nav tab that preserves its own
/// Navigator stack independently.
///
/// To add a new tab:
///   1. Add a [StatefulShellBranch] here
///   2. Add a matching [_NavItem] in [MainShell._items]
///   (order must match)
abstract class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: false,
    // Uncomment to add auth guard:
    // redirect: _guardRoute,
    routes: [
      // ── Full-screen routes (outside shell) ──────────────────────────────
      // GoRoute(
      //   path: LoginPage.route.path,
      //   name: LoginPage.route.name,
      //   builder: (_, __) => const LoginPage(),
      // ),

      // ── Shell (bottom nav tabs) ──────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Branch 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                // Replace with real page + BlocProvider:
                builder: (_, _) => const _PlaceholderPage(label: 'Home'),
                // builder: (context, state) => BlocProvider(
                //   create: (_) => sl<HomeBloc>(),
                //   child: const HomePage(),
                // ),
              ),
            ],
          ),
          // Add more branches for each tab:
          // StatefulShellBranch(
          //   routes: [
          //     GoRoute(
          //       path: ProductPage.route.path,
          //       name: ProductPage.route.name,
          //       builder: (context, state) => BlocProvider(
          //         create: (_) => sl<ProductBloc>(),
          //         child: const ProductPage(),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      child: _ErrorPage(
        error: state.error?.message ?? 'Halaman tidak ditemukan',
      ),
    ),
  );

  // static String? _guardRoute(BuildContext context, GoRouterState state) {
  //   final isLoggedIn = sl<AuthInterceptor>()
  //       .authenticationStatus
  //       .isBroadcast; // replace with actual check
  //   final isOnLogin = state.matchedLocation == '/login';
  //   if (!isLoggedIn && !isOnLogin) return '/login';
  //   if (isLoggedIn && isOnLogin) return '/home';
  //   return null;
  // }
}

class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  final String error;
  const _ErrorPage({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
''';

  // ─── app_colors.dart ──────────────────────────────────────────────────────

  static String appColors() => r'''
import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark  = Color(0xFF3730A3);

  static const Color secondary      = Color(0xFF0EA5E9);
  static const Color secondaryLight = Color(0xFF38BDF8);
  static const Color secondaryDark  = Color(0xFF0369A1);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // ── Neutral ───────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFFF8FAFC);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color divider        = Color(0xFFE2E8F0);
  static const Color border         = Color(0xFFE2E8F0);

  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled  = Color(0xFFCBD5E1);
  static const Color textInverse   = Color(0xFFFFFFFF);

  // ── Status badge map ──────────────────────────────────────────────────────
  static const Map<String, Color> statusColors = {
    'active'   : success,
    'inactive' : textSecondary,
    'pending'  : warning,
    'cancelled': error,
    'completed': success,
    'approved' : success,
    'rejected' : error,
    'draft'    : textSecondary,
    'open'     : info,
  };
}
''';

  // ─── app_typography.dart ──────────────────────────────────────────────────

  static String appTypography() => r'''
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Usage:
//
//   AppTypography.xs.regular
//   AppTypography.m.semiBold
//   AppTypography.xl.bold.copyWith(color: Colors.red)
//
//   // Override font (keeps size/weight/height):
//   AppTypography.m.semiBold.withFont(GoogleFonts.poppins)
// ─────────────────────────────────────────────────────────────────────────────

class TypeScale {
  final double _size;
  final double? _height;

  const TypeScale(this._size, {double? height}) : _height = height;

  TextStyle _base(FontWeight w) => GoogleFonts.outfit(
        fontSize: _size,
        fontWeight: w,
        height: _height,
      );

  TextStyle get light    => _base(FontWeight.w300);
  TextStyle get regular  => _base(FontWeight.w400);
  TextStyle get medium   => _base(FontWeight.w500);
  TextStyle get semiBold => _base(FontWeight.w600);
  TextStyle get bold     => _base(FontWeight.w700);
}

extension TextStyleFontX on TextStyle {
  /// Switch font family while keeping all other properties intact.
  TextStyle withFont(TextStyle Function(TextStyle) googleFontFn) =>
      googleFontFn(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// | Scale | Size | Weights                                  |
// |-------|------|------------------------------------------|
// | xs    | 10   | light, regular, medium                   |
// | s     | 12   | light, regular, medium, semiBold         |
// | m     | 14   | light, regular, medium, semiBold, bold   |
// | l     | 16   | regular, medium, semiBold                |
// | xl    | 18   | regular, medium, semiBold                |
// | xxl   | 24   | medium, semiBold                         |
// | xxxl  | 28   | semiBold                                 |
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppTypography {
  AppTypography._();

  static const TypeScale xs   = TypeScale(10);
  static const TypeScale s    = TypeScale(12);
  static const TypeScale m    = TypeScale(14);
  static const TypeScale l    = TypeScale(16);
  static const TypeScale xl   = TypeScale(18);
  static const TypeScale xxl  = TypeScale(24);
  static const TypeScale xxxl = TypeScale(28);

  // ── Shortcuts ─────────────────────────────────────────────────────────────
  static TextStyle get caption    => xs.regular;
  static TextStyle get bodySmall  => s.regular;
  static TextStyle get body       => m.regular;
  static TextStyle get bodyMedium => m.medium;
  static TextStyle get title      => l.semiBold;
  static TextStyle get titleLarge => xl.semiBold;
  static TextStyle get heading    => xxl.semiBold;
  static TextStyle get display    => xxxl.semiBold;
}
''';

  // ─── app_theme.dart ───────────────────────────────────────────────────────

  static String appTheme() => r'''
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(_textTheme),
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          error: AppColors.error,
          surface: AppColors.surface,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTypography.l.semiBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: AppTypography.m.semiBold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(39),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTypography.m.semiBold,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(39),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          labelStyle: AppTypography.s.regular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
      );

  static TextTheme get _textTheme => TextTheme(
        displayLarge:   AppTypography.xxxl.semiBold,
        displayMedium:  AppTypography.xxl.semiBold,
        displaySmall:   AppTypography.xxl.medium,
        headlineLarge:  AppTypography.xl.semiBold,
        headlineMedium: AppTypography.l.semiBold,
        headlineSmall:  AppTypography.l.medium,
        titleLarge:     AppTypography.m.semiBold,
        titleMedium:    AppTypography.m.medium,
        titleSmall:     AppTypography.s.semiBold,
        bodyLarge:      AppTypography.m.regular,
        bodyMedium:     AppTypography.s.regular,
        bodySmall:      AppTypography.xs.regular,
        labelLarge:     AppTypography.m.medium,
        labelMedium:    AppTypography.s.medium,
        labelSmall:     AppTypography.xs.medium,
      );
}
''';

  // ─── app_logger.dart ──────────────────────────────────────────────────────

  static String appLogger() => r'''
abstract class AppLogger {
  const AppLogger._();

  static void debug(String msg, {String? tag}) => _log('🐛 DEBUG', msg, tag);
  static void info(String msg,  {String? tag}) => _log('ℹ️  INFO ', msg, tag);
  static void warn(String msg,  {String? tag}) => _log('⚠️  WARN ', msg, tag);

  static void error(
    String msg, {
    Object? error,
    StackTrace? stack,
    String? tag,
  }) {
    _log('🔴 ERROR', msg, tag);
    if (error != null) _p('   ↳ $error');
    if (stack != null) _p('   ↳ $stack');
  }

  static void _log(String level, String msg, String? tag) {
    assert(() {
      _p('$level ${tag != null ? '[$tag] ' : ''}$msg');
      return true;
    }());
  }

  // ignore: avoid_print
  static void _p(String msg) => print(msg);
}
''';

  // ─── formatters.dart ──────────────────────────────────────────────────────

  static String formatters() => r'''
import 'package:intl/intl.dart';

abstract class Formatters {
  const Formatters._();

  static final _idr      = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static final _date     = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _short    = DateFormat('dd/MM/yyyy');
  static final _time     = DateFormat('HH:mm');
  static final _month    = DateFormat('MMM yyyy', 'id_ID');

  static String currency(num? v)    => v == null ? 'Rp -' : _idr.format(v);
  static String date(DateTime? d)   => d == null ? '-' : _date.format(d);
  static String dateTime(DateTime? d) => d == null ? '-' : _dateTime.format(d);
  static String shortDate(DateTime? d) => d == null ? '-' : _short.format(d);
  static String time(DateTime? d)   => d == null ? '-' : _time.format(d);
  static String monthYear(DateTime? d) => d == null ? '-' : _month.format(d);

  static String compact(num? n) {
    if (n == null) return '0';
    if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}B';
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  static String titleCase(String? s) {
    if (s == null || s.isEmpty) return '';
    return s
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
''';

  // ─── responsive.dart ──────────────────────────────────────────────────────

  static String responsive() => r'''
import 'package:flutter/material.dart';

abstract class Responsive {
  const Responsive._();

  static const double _mobileBreak = 600;
  static const double _tabletBreak = 1024;

  static bool isMobile(BuildContext ctx)  => _w(ctx) < _mobileBreak;
  static bool isTablet(BuildContext ctx)  => _w(ctx) >= _mobileBreak && _w(ctx) < _tabletBreak;
  static bool isDesktop(BuildContext ctx) => _w(ctx) >= _tabletBreak;

  static double _w(BuildContext ctx) => MediaQuery.sizeOf(ctx).width;

  static T value<T>(
    BuildContext ctx, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(ctx)) return desktop;
    if (isTablet(ctx))  return tablet ?? desktop;
    return mobile;
  }

  static EdgeInsets pagePadding(BuildContext ctx) => value(
        ctx,
        mobile:  const EdgeInsets.all(16),
        tablet:  const EdgeInsets.all(24),
        desktop: const EdgeInsets.all(32),
      );

  static int gridColumns(BuildContext ctx) => value(ctx, mobile: 1, tablet: 2, desktop: 3);
}
''';

  // ─── paginated_result.dart ────────────────────────────────────────────────

  static String paginatedResult() => r'''
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  int get totalPages   => (totalCount / pageSize).ceil();
  bool get hasNextPage => page < totalPages;
  bool get hasPrevPage => page > 1;
  bool get isEmpty     => items.isEmpty;

  PaginatedResult<T> copyWith({List<T>? items, int? totalCount}) =>
      PaginatedResult(
        items: items ?? this.items,
        totalCount: totalCount ?? this.totalCount,
        page: page,
        pageSize: pageSize,
      );

  PaginatedResult<R> map<R>(R Function(T) mapper) => PaginatedResult(
        items: items.map(mapper).toList(),
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
      );
}
''';

  // ─── helper_mixin.dart ────────────────────────────────────────────────────

  static String helperMixin() => r'''
import 'package:flutter/material.dart';

mixin HelperMixin {
  void showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  void dismissKeyboard(BuildContext context) =>
      FocusScope.of(context).unfocus();

  void showLoadingDialog(BuildContext context, {String message = 'Please wait...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  void hideLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }
}
''';

  // ─── main.dart ────────────────────────────────────────────────────────────

  static String mainDart(String projectName) => '''
import 'package:flutter/material.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '$projectName',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
''';
}
