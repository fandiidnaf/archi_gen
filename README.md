# archi_gen

[![pub.dev](https://img.shields.io/badge/pub.dev-v0.5.0-blue)](https://pub.dev/packages/archi_gen)
[![Dart SDK](https://img.shields.io/badge/Dart-≥3.0.0-blue)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

> CLI tool to scaffold **Flutter Clean Architecture** instantly.  
> Zero boilerplate. Start shipping features.

---

## Stack

| Concern | Package |
|---------|---------|
| State | `flutter_bloc ^latest` |
| Navigation | `go_router ^latest` — `StatefulShellRoute.indexedStack` |
| DI | `get_it ^latest` |
| Functional | `fpdart ^latest` — `Either<Failure, T>` |
| HTTP | `dio ^latest` |
| Token refresh | `fresh_dio ^latest` — auto Bearer + refresh on 401 |
| Logging | `pretty_dio_logger ^latest` — debug only |
| Token storage | `shared_preferences ^latest` |
| Typography | `google_fonts ^latest` — Outfit |
| Equality | `equatable ^latest` |
| Formatting | `intl ^latest` |

---

## Installation

```yaml
dev_dependencies:
  archi_gen: any
```

```bash
flutter pub get
```

---

## Commands

| Command | What it does |
|---------|-------------|
| `init` | Generate `core/` + run `flutter pub add` for all deps |
| `feature <n>` | Generate full feature (domain / data / presentation) |
| `feature <n> --with-form` | Same + a create/edit form page |
| `preset auth` | LoginPage, ProfilePage, AuthBloc, 3 usecases, Dio datasource |
| `preset dashboard` | KPI cards, bar chart, activity feed, DashboardBloc |
| `list` | Show all features with layer breakdown |
| `remove <n>` | Delete a feature folder (with confirmation) |
| `doctor` | Check deps, core files, route registration |

---

## Quick start

```bash
dart run archi_gen init
dart run archi_gen feature product
dart run archi_gen feature invoice --with-form
dart run archi_gen preset auth
dart run archi_gen doctor
```

---

## `init` — generated core structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart        ← baseUrl, timeouts, storage keys
│   ├── di/
│   │   └── service_locator.dart      ← GetIt, registers Dio+interceptors
│   ├── errors/
│   │   └── failures.dart             ← Failure hierarchy for Either
│   ├── extensions/
│   │   └── num_ext.dart              ← 12.h → SizedBox(height:12)
│   ├── mixins/
│   │   └── helper_mixin.dart         ← showSnack, showLoadingDialog
│   ├── network/
│   │   ├── dio_client.dart           ← DioClient.create() factory
│   │   ├── token_storage.dart        ← AppToken + AppTokenStorage
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart ← fresh_dio token attach + refresh
│   │       ├── error_interceptor.dart← DioException → AppException
│   │       └── logging_interceptor.dart ← PrettyDioLogger (debug only)
│   ├── router/
│   │   ├── app_router.dart           ← StatefulShellRoute.indexedStack
│   │   └── route_structure.dart      ← RouteStructure(path, name)
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_theme.dart            ← Material 3 + AppTypography TextTheme
│   │   └── app_typography.dart       ← TypeScale xs/s/m/l/xl/xxl/xxxl
│   ├── usecases/
│   │   └── usecase.dart              ← UseCase<T,Params> base class
│   ├── utils/
│   │   ├── app_logger.dart
│   │   ├── formatters.dart           ← currency, date, compact
│   │   ├── paginated_result.dart     ← PaginatedResult<T>
│   │   └── responsive.dart
│   └── widgets/
│       ├── common/
│       │   ├── app_card.dart
│       │   ├── app_data_table.dart
│       │   ├── confirm_dialog.dart   ← ConfirmDialog.show(context,...)
│       │   ├── empty_state.dart
│       │   ├── loading_widget.dart
│       │   ├── permission_guard.dart
│       │   ├── search_filter_bar.dart
│       │   └── status_badge.dart
│       └── shell/
│           └── main_shell.dart       ← Bottom nav via StatefulNavigationShell
└── main.dart                         ← async main + await configureDependencies()
```

---

## Network layer (`core/network/`)

### `DioClient.create(tokenStorage:)`

Builds Dio with interceptors in the correct order:

```
Request →  ErrorInterceptor → AuthInterceptor → Logger
Response ← Logger → AuthInterceptor → ErrorInterceptor
```

### `AuthInterceptor` (fresh_dio ^0.5.1)

```dart
// After login — persist the token:
sl<AuthInterceptor>().setToken(
  AppToken(accessToken: 'xxx', refreshToken: 'yyy'),
);

// On logout:
sl<AuthInterceptor>().revokeToken();

// Listen to auth state changes:
sl<AuthInterceptor>().authenticationStatus.listen((status) {
  if (status == AuthenticationStatus.unauthenticated) {
    context.go('/login');
  }
});
```

On 401, `fresh_dio` calls `POST /auth/refresh` automatically, saves the new token, and retries the original request — all transparently.

### `ErrorInterceptor`

Maps every `DioException` to a typed `AppException`:

```dart
// In repository catch block:
} on DioException catch (e) {
  final failure = (e.error as AppException?)?.toFailure()
      ?? ServerFailure(e.message ?? 'Unknown error');
  return Left(failure);
}
```

Covers: timeout, no-connection, 400, 401, 403, 404, 422, 429, 5xx.

---

## `feature <n>` — generated structure

```
lib/features/product/
├── domain/
│   ├── entities/product_entity.dart
│   ├── repositories/product_repository.dart
│   └── usecases/get_product_usecase.dart
├── data/
│   ├── models/product_model.dart
│   ├── datasources/product_remote_datasource.dart  ← Dio
│   └── repositories/product_repository_impl.dart   ← Either + DioException
└── presentation/
    ├── bloc/
    │   ├── product_bloc.dart
    │   ├── product_event.dart   ← LoadAll | LoadById | Create | Update | Delete | Reset
    │   └── product_state.dart   ← Initial | Loading | Loaded | DetailLoaded | ActionSuccess | Error
    └── pages/
        ├── product_page.dart       ← RouteStructure.route declared here
        └── product_form_page.dart  ← only with --with-form
```

Each page declares:
```dart
static const RouteStructure route = RouteStructure(
  path: '/products',
  name: 'products',
);
```

---

## Typography system

```dart
// xs(10) s(12) m(14) l(16) xl(18) xxl(24) xxxl(28)
AppTypography.m.semiBold
AppTypography.xl.bold.copyWith(color: AppColors.primary)

// Shortcuts
AppTypography.body      // m.regular
AppTypography.title     // l.semiBold
AppTypography.heading   // xxl.semiBold

// Switch font (keeps size/weight)
AppTypography.m.semiBold.withFont(GoogleFonts.poppins)
```

---

## `doctor`

```
dart run archi_gen doctor
```

Checks 30+ core files, all required deps, feature integrity, and route registration. Prints ✓/⚠/✗ per item with a summary.

---

## Upload to GitHub & pub.dev

### GitHub

```bash
cd your_package_folder
git init
git add .
git commit -m "feat: initial release v0.5.0"
git remote add origin https://github.com/YOUR_USERNAME/archi_gen.git
git branch -M main
git push -u origin main
git tag v0.5.0 && git push origin v0.5.0
```

Update `pubspec.yaml`:
```yaml
homepage: https://github.com/YOUR_USERNAME/archi_gen
repository: https://github.com/YOUR_USERNAME/archi_gen
```

### pub.dev

```bash
# Dry run — checks everything without publishing
dart pub publish --dry-run

# Publish
dart pub publish
```

Requirements for pub.dev:
- `pubspec.yaml`: `name`, `description` (60+ chars), `version`, `homepage`
- `README.md`, `CHANGELOG.md`, `LICENSE` all present
- No analyzer errors: `dart analyze`

---

## Roadmap

- [ ] `preset user_management`
- [ ] Interactive mode (prompts when no args)
- [ ] `--riverpod` flag

---

## License

MIT
