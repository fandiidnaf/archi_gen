## 0.5.1
-  update README.md

## 0.5.0

### New: `core/network/` folder

`init` now generates a complete, production-ready network layer:

```
core/network/
├── dio_client.dart                          ← DioClient.create() factory
├── token_storage.dart                       ← AppToken + AppTokenStorage
└── interceptors/
    ├── auth_interceptor.dart                ← fresh_dio ^0.5.1 token attach + auto-refresh
    ├── error_interceptor.dart               ← DioException → AppException → Failure
    └── logging_interceptor.dart             ← PrettyDioLogger (debug only)
```

**`token_storage.dart`** — `AppToken` implements `Token` from `fresh_dio`. `AppTokenStorage` persists to `SharedPreferences`.

**`auth_interceptor.dart`** — Uses `Fresh.oAuth2()`. Auto-attaches `Authorization: Bearer`. On 401 calls `/auth/refresh`, retries transparently. Exposes `setToken()`, `revokeToken()`, `authenticationStatus` stream.

**`error_interceptor.dart`** — Maps every `DioException` to a typed `AppException` covering timeout, no-connection, 400–5xx. `AppException.toFailure()` maps to domain `Failure` types.

**`logging_interceptor.dart`** — `PrettyDioLogger` only in `kDebugMode`.

**`dio_client.dart`** — `DioClient.create(tokenStorage:)` factory with correct interceptor order: ErrorInterceptor → AuthInterceptor → Logger.

**`service_locator.dart`** — Registers `SharedPreferences`, `AppTokenStorage`, `Dio`, `AuthInterceptor`. Now `async`.

**`main()`** — Now `async` + `await configureDependencies()`.

### New deps added by `init`
- `fresh_dio: ^0.5.1`
- `pretty_dio_logger: ^3.4.0`
- `shared_preferences: ^2.3.5`

---

## 0.4.0
- Supabase removed, Dio only
- StatefulShellRoute.indexedStack
- AppTypography, RouteStructure, num extensions

## 0.3.0
- doctor, preset dashboard, remove commands

## 0.2.0
- preset auth, --with-form, list, remove

## 0.1.0
- Initial: init, feature commands
