class AuthPresetTemplates {
  // ─── Domain: Profile Entity ───────────────────────────────────────────────

  static String profileEntity() => r'''
import 'package:equatable/equatable.dart';

enum UserRole { admin, manager, staff, viewer }

class Profile extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get isAdmin   => role == UserRole.admin;
  bool get isManager => role == UserRole.manager || isAdmin;

  Profile copyWith({
    String? fullName,
    UserRole? role,
    String? avatarUrl,
  }) =>
      Profile(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, email, fullName, role, avatarUrl, createdAt];
}
''';

  // ─── Domain: Auth Repository ──────────────────────────────────────────────

  static String authRepository() => r'''
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile.dart';

abstract class AuthRepository {
  Future<Either<Failure, Profile>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, Profile>> getCurrentProfile();

  Future<Either<Failure, Profile>> refreshToken();
}
''';

  // ─── Domain: UseCases ────────────────────────────────────────────────────

  static String signInUseCase() => r'''
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase implements UseCase<Profile, SignInParams> {
  final AuthRepository repository;
  SignInUseCase(this.repository);

  @override
  Future<Either<Failure, Profile>> call(SignInParams params) =>
      repository.signIn(email: params.email, password: params.password);
}

class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
''';

  static String signOutUseCase() => r'''
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SignOutUseCase implements UseCase<Unit, NoParams> {
  final AuthRepository repository;
  SignOutUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      repository.signOut();
}
''';

  static String getCurrentProfileUseCase() => r'''
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile.dart';
import '../repositories/auth_repository.dart';

class GetCurrentProfileUseCase implements UseCase<Profile, NoParams> {
  final AuthRepository repository;
  GetCurrentProfileUseCase(this.repository);

  @override
  Future<Either<Failure, Profile>> call(NoParams params) =>
      repository.getCurrentProfile();
}
''';

  // ─── Data: Profile Model ──────────────────────────────────────────────────

  static String profileModel() => r'''
import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.avatarUrl,
    required super.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String? ?? '',
        role: _parseRole(json['role'] as String?),
        avatarUrl: json['avatar_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role.name,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };

  Profile toEntity() => Profile(
        id: id,
        email: email,
        fullName: fullName,
        role: role,
        avatarUrl: avatarUrl,
        createdAt: createdAt,
      );

  static UserRole _parseRole(String? role) => switch (role?.toLowerCase()) {
        'admin'   => UserRole.admin,
        'manager' => UserRole.manager,
        'staff'   => UserRole.staff,
        _         => UserRole.viewer,
      };
}

class AuthResponseModel {
  final ProfileModel profile;
  final String accessToken;
  final String refreshToken;

  const AuthResponseModel({
    required this.profile,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      profile: ProfileModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }
}
''';

  // ─── Data: Remote Datasource (Dio) ────────────────────────────────────────

  static String authRemoteDatasource() => r'''
import 'package:dio/dio.dart';
import '../models/profile_model.dart';

abstract class AuthRemoteDatasource {
  Future<AuthResponseModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<ProfileModel> getCurrentProfile();

  Future<AuthResponseModel> refreshToken(String refreshToken);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final Dio dio;

  AuthRemoteDatasourceImpl({required this.dio});

  @override
  Future<AuthResponseModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponseModel.fromJson(response.data!);
  }

  @override
  Future<void> signOut() async {
    await dio.post<void>('/auth/logout');
  }

  @override
  Future<ProfileModel> getCurrentProfile() async {
    final response = await dio.get<Map<String, dynamic>>('/auth/me');
    return ProfileModel.fromJson(response.data!);
  }

  @override
  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return AuthResponseModel.fromJson(response.data!);
  }
}
''';

  // ─── Data: Repository Impl ────────────────────────────────────────────────

  static String authRepositoryImpl() => r'''
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, Profile>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDatasource.signIn(
        email: email,
        password: password,
      );
      // TODO: persist tokens via SharedPreferences / FlutterSecureStorage
      // await _tokenStorage.save(result.accessToken, result.refreshToken);
      return Right(result.profile.toEntity());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(UnauthorizedFailure('Invalid email or password'));
      }
      return Left(ServerFailure(e.message ?? 'Network error'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await remoteDatasource.signOut();
      // TODO: clear stored tokens
      return const Right(unit);
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Profile>> getCurrentProfile() async {
    try {
      final result = await remoteDatasource.getCurrentProfile();
      return Right(result.toEntity());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(UnauthorizedFailure());
      }
      return Left(ServerFailure(e.message ?? 'Network error'));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Profile>> refreshToken() async {
    try {
      // TODO: load stored refresh token
      const storedRefreshToken = '';
      final result = await remoteDatasource.refreshToken(storedRefreshToken);
      return Right(result.profile.toEntity());
    } on Exception catch (e) {
      return Left(UnauthorizedFailure(e.toString()));
    }
  }
}
''';

  // ─── Presentation: BLoC ───────────────────────────────────────────────────

  static String authEvent() => r'''
part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested({required this.email, required this.password});
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
''';

  static String authState() => r'''
part of 'auth_bloc.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final Profile profile;
  const AuthAuthenticated(this.profile);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
''';

  static String authBloc() => r'''
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/get_current_profile_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase signIn;
  final SignOutUseCase signOut;
  final GetCurrentProfileUseCase getCurrentProfile;

  AuthBloc({
    required this.signIn,
    required this.signOut,
    required this.getCurrentProfile,
  }) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignOutRequested>(_onSignOut);
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await getCurrentProfile(const NoParams());
    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (profile) => emit(AuthAuthenticated(profile)),
    );
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await signIn(
      SignInParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (profile) => emit(AuthAuthenticated(profile)),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await signOut(const NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }
}
''';

  // ─── Presentation: Pages ──────────────────────────────────────────────────

  static String loginPage() => r'''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/route_structure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  static const RouteStructure route = RouteStructure(
    path: '/login',
    name: 'login',
  );

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthSignInRequested(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 56,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: AppTypography.xxl.semiBold.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your account',
                          textAlign: TextAlign.center,
                          style: AppTypography.m.regular.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email wajib diisi';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(context),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password wajib diisi';
                                  }
                                  if (v.length < 6) {
                                    return 'Minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: isLoading ? null : () => _submit(context),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: isLoading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign In'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
''';

  static String profilePage() => r'''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_structure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/common/confirm_dialog.dart';
import '../bloc/auth_bloc.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  static const RouteStructure route = RouteStructure(
    path: '/profile',
    name: 'profile',
  );

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go(LoginPage.route.path);
          }
        },
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = state.profile;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName[0].toUpperCase()
                              : '?',
                          style: AppTypography.xxl.bold.copyWith(
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(profile.fullName, style: AppTypography.xl.semiBold),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: AppTypography.m.regular.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(profile.role.name.toUpperCase()),
                  backgroundColor: AppColors.primaryLight.withValues(alpha: .15),
                  labelStyle: AppTypography.s.medium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: Text(
                    'Sign Out',
                    style: AppTypography.m.medium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'Sign Out',
                      message: 'Apakah kamu yakin ingin keluar?',
                      confirmLabel: 'Keluar',
                      isDangerous: true,
                    );
                    if (confirmed && context.mounted) {
                      context
                          .read<AuthBloc>()
                          .add(const AuthSignOutRequested());
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
''';
}
