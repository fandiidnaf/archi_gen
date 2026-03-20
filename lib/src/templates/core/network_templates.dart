/// Templates for `core/network/`.
class NetworkTemplates {
  // ─── token_storage.dart ───────────────────────────────────────────────────

  static String tokenStorage() => r'''
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_dio/fresh_dio.dart';

/// Persists [OAuth2Token] to [FlutterSecureStorage].
///
/// Uses platform keychain (iOS) / keystore (Android) — tokens are never
/// written to plain storage.
///
/// [AndroidOptions] uses RSA OAEP + AES-GCM by default (v9+).
class AppTokenStorage implements TokenStorage<OAuth2Token> {
  static const _key = 'app_oauth2_token';

  final FlutterSecureStorage _storage;

  const AppTokenStorage(this._storage);

  @override
  Future<OAuth2Token?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return OAuth2Token(
        accessToken:  json['access_token']  as String,
        tokenType:    json['token_type']    as String? ?? 'bearer',
        refreshToken: json['refresh_token'] as String?,
        expiresIn:    json['expires_in']    as int?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(OAuth2Token? token) async {
    if (token == null) {
      await _storage.delete(key: _key);
      return;
    }
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'access_token':  token.accessToken,
        'token_type':    token.tokenType,
        'refresh_token': token.refreshToken,
        'expires_in':    token.expiresIn,
      }),
    );
  }

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

/// Creates a [FlutterSecureStorage] instance 
///
/// Android: Maximum security storage with optional biometric authentication.
/// iOS/macOS: Keychain with standard accessibility
FlutterSecureStorage createSecureStorage() => const FlutterSecureStorage(
      aOptions: AndroidOptions.biometric(),
      );
''';

  // ─── interceptors/auth_interceptor.dart ───────────────────────────────────

  static String authInterceptor() => r'''
import 'package:fresh_dio/fresh_dio.dart';
import '../token_storage.dart';

/// Token-refresh interceptor using [fresh_dio] ^0.5.1 with [OAuth2Token].
///
/// What it does:
/// • Reads the stored [OAuth2Token] from [AppTokenStorage] before each request.
/// 
/// • Injects `Authorization: Bearer <accessToken>` header automatically.
/// 
/// • On a 401 response, calls [_doRefresh] with a fresh (no-auth) Dio
///   to hit `/auth/refresh` and gets a new [OAuth2Token].
/// 
/// • Retries the original request with the new token transparently.
/// 
/// • If refresh fails, throws [RevokeTokenException] → stored token is
///   cleared and [authenticationStatus] emits [AuthenticationStatus.unauthenticated].
///
/// Usage after login:
/// ```dart
/// await sl<AuthInterceptor>().setToken(
///   const OAuth2Token(
///     accessToken: 'xxx',
///     refreshToken: 'yyy',
///     expiresIn: 3600,
///   ),
/// );
/// ```
///
/// On logout:
/// ```dart
/// await sl<AuthInterceptor>().revokeToken();
/// ```
///
/// Listen to auth state changes:
/// ```dart
/// sl<AuthInterceptor>().authenticationStatus.listen((status) {
///   if (status == AuthenticationStatus.unauthenticated) {
///     context.go('/login');
///   }
/// });
/// ```
class AuthInterceptor {
  late final Fresh<OAuth2Token> fresh;

  AuthInterceptor({required AppTokenStorage tokenStorage, required Dio dio}) {
    fresh = Fresh.oAuth2(
      tokenStorage: tokenStorage,
      refreshToken: (token, httpClient) => _doRefresh(token, httpClient),
      shouldRefresh: (response) => response?.statusCode == 401,
    );
    dio.interceptors.add(fresh);
  }

  /// Calls the refresh endpoint with a clean [Dio] (no auth interceptor)
  /// to avoid infinite retry loops.
  static Future<OAuth2Token> _doRefresh(
    OAuth2Token? token,
    Dio httpClient,
  ) async {
    try {
      final response = await httpClient.post<Map<String, dynamic>>(
        'https://example.com/auth/refresh',
        data: {'refresh_token': token?.refreshToken},
      );
      final data = response.data!;
      return OAuth2Token(
        accessToken: data['access_token'] as String,
        tokenType: data['token_type'] as String? ?? 'bearer',
        refreshToken: data['refresh_token'] as String?,
        expiresIn: data['expires_in'] as int?,
      );
    } catch (_) {
      throw RevokeTokenException();
    }
  }

  /// Stream of auth state changes.
  Stream<AuthenticationStatus> get authenticationStatus =>
      fresh.authenticationStatus;

  /// Persist a token after successful login.
  Future<void> setToken(OAuth2Token token) => fresh.setToken(token);

  /// Clear token on logout.
  Future<void> revokeToken() => fresh.revokeToken();
}
''';

  // ─── interceptors/error_interceptor.dart ──────────────────────────────────

  static String errorInterceptor() => r'''
import 'package:dio/dio.dart';
import '../../errors/failures.dart';

/// Converts every [DioException] into a typed [AppException].
///
/// In your repository catch block:
/// ```dart
/// } on DioException catch (e) {
///   final failure = (e.error as AppException?)?.toFailure()
///       ?? ServerFailure(e.message ?? 'Unknown error');
///   return Left(failure);
/// }
/// ```
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(
      err.copyWith(
        error: _map(err),
        message: _map(err).message,
      ),
    );
  }

  AppException _map(DioException err) {
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const AppException(
          message: 'Connection timed out. Check your internet connection.',
          type: AppExceptionType.timeout,
        ),
      DioExceptionType.badResponse =>
        _mapStatus(err.response?.statusCode, err.response?.data),
      DioExceptionType.cancel => const AppException(
          message: 'Request was cancelled.',
          type: AppExceptionType.cancelled,
        ),
      DioExceptionType.connectionError => const AppException(
          message: 'No internet connection.',
          type: AppExceptionType.noConnection,
        ),
      _ => AppException(
          message: err.message ?? 'An unexpected error occurred.',
          type: AppExceptionType.unknown,
        ),
    };
  }

  AppException _mapStatus(int? code, dynamic data) {
    final msg = _extractMessage(data);
    return switch (code) {
      400    => AppException(message: msg ?? 'Bad request.',          type: AppExceptionType.badRequest,   statusCode: 400),
      401    => AppException(message: msg ?? 'Unauthorized.',         type: AppExceptionType.unauthorized, statusCode: 401),
      403    => AppException(message: msg ?? 'Forbidden.',            type: AppExceptionType.forbidden,    statusCode: 403),
      404    => AppException(message: msg ?? 'Resource not found.',   type: AppExceptionType.notFound,     statusCode: 404),
      422    => AppException(message: msg ?? 'Validation error.',     type: AppExceptionType.validation,   statusCode: 422),
      429    => AppException(message: msg ?? 'Too many requests.',    type: AppExceptionType.rateLimited,  statusCode: 429),
      int c when c >= 500 => AppException(message: msg ?? 'Server error.',        type: AppExceptionType.serverError,  statusCode: code),
      _      => AppException(message: msg ?? 'HTTP error $code',     type: AppExceptionType.unknown,      statusCode: code),
    };
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
             data['error']   as String? ??
             data['detail']  as String?;
    }
    return null;
  }
}

enum AppExceptionType {
  timeout, noConnection, badRequest, unauthorized, forbidden,
  notFound, validation, rateLimited, serverError, cancelled, unknown,
}

class AppException implements Exception {
  final String message;
  final AppExceptionType type;
  final int? statusCode;

  const AppException({
    required this.message,
    required this.type,
    this.statusCode,
  });

  Failure toFailure() => switch (type) {
        AppExceptionType.unauthorized => UnauthorizedFailure(message),
        AppExceptionType.notFound     => NotFoundFailure(message),
        AppExceptionType.validation   => ValidationFailure(message),
        AppExceptionType.noConnection ||
        AppExceptionType.timeout      => NetworkFailure(message),
        _                             => ServerFailure(message),
      };

  @override
  String toString() => 'AppException($type, $message)';
}
''';

  // ─── interceptors/logging_interceptor.dart ────────────────────────────────

  static String loggingInterceptor() => r'''
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Returns a [PrettyDioLogger] for development builds.
/// Only add this in [kDebugMode].
Interceptor createLoggingInterceptor() => PrettyDioLogger(
      requestHeader:  true,
      requestBody:    true,
      responseHeader: false,
      responseBody:   true,
      error:          true,
      compact:        true,
      maxWidth:       90,
    );
''';

  // ─── dio_client.dart ──────────────────────────────────────────────────────

  static String dioClient() => r'''
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'token_storage.dart';

/// Factory that builds and wires the app [Dio] instance.
///
/// Interceptor order (request top→bottom, response bottom→top):
///   1. [ErrorInterceptor]  — normalise DioException → AppException
///   2. [AuthInterceptor]   — Bearer token attach + auto-refresh on 401
///   3. Logger              — log final request/response (debug only)
abstract class DioClient {
  DioClient._();

  static Dio create({required AppTokenStorage tokenStorage}) {
    final dio = Dio(
      BaseOptions(
        baseUrl:        AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout:    AppConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      ErrorInterceptor(),
      AuthInterceptor(tokenStorage: tokenStorage, dio: dio).fresh,
      if (kDebugMode) createLoggingInterceptor(),
    ]);

    return dio;
  }
}
''';
}
