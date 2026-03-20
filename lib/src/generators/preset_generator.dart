import '../utils/file_helper.dart';
import '../utils/logger.dart';
import '../templates/presets/auth_preset_templates.dart';
import '../templates/presets/dashboard_preset_templates.dart';

class PresetGenerator {
  // ─── Auth ──────────────────────────────────────────────────────────────────

  static Future<void> auth({bool force = false}) async {
    CliLogger.section('Domain Layer');
    await _w(
      ['features', 'auth', 'domain', 'entities', 'profile.dart'],
      AuthPresetTemplates.profileEntity(),
      force,
    );
    await _w(
      ['features', 'auth', 'domain', 'repositories', 'auth_repository.dart'],
      AuthPresetTemplates.authRepository(),
      force,
    );
    await _w(
      ['features', 'auth', 'domain', 'usecases', 'sign_in_usecase.dart'],
      AuthPresetTemplates.signInUseCase(),
      force,
    );
    await _w(
      ['features', 'auth', 'domain', 'usecases', 'sign_out_usecase.dart'],
      AuthPresetTemplates.signOutUseCase(),
      force,
    );
    await _w(
      [
        'features',
        'auth',
        'domain',
        'usecases',
        'get_current_profile_usecase.dart',
      ],
      AuthPresetTemplates.getCurrentProfileUseCase(),
      force,
    );

    CliLogger.section('Data Layer');
    await _w(
      ['features', 'auth', 'data', 'models', 'profile_model.dart'],
      AuthPresetTemplates.profileModel(),
      force,
    );
    await _w(
      [
        'features',
        'auth',
        'data',
        'datasources',
        'auth_remote_datasource.dart',
      ],
      AuthPresetTemplates.authRemoteDatasource(),
      force,
    );
    await _w(
      ['features', 'auth', 'data', 'repositories', 'auth_repository_impl.dart'],
      AuthPresetTemplates.authRepositoryImpl(),
      force,
    );

    CliLogger.section('Presentation Layer');
    await _w(
      ['features', 'auth', 'presentation', 'bloc', 'auth_event.dart'],
      AuthPresetTemplates.authEvent(),
      force,
    );
    await _w(
      ['features', 'auth', 'presentation', 'bloc', 'auth_state.dart'],
      AuthPresetTemplates.authState(),
      force,
    );
    await _w(
      ['features', 'auth', 'presentation', 'bloc', 'auth_bloc.dart'],
      AuthPresetTemplates.authBloc(),
      force,
    );
    await _w(
      ['features', 'auth', 'presentation', 'pages', 'login_page.dart'],
      AuthPresetTemplates.loginPage(),
      force,
    );
    await _w(
      ['features', 'auth', 'presentation', 'pages', 'profile_page.dart'],
      AuthPresetTemplates.profilePage(),
      force,
    );
  }

  // ─── Dashboard ─────────────────────────────────────────────────────────────

  static Future<void> dashboard({
    required String projectName,
    bool force = false,
  }) async {
    CliLogger.section('Data Layer');
    await _w(
      ['features', 'dashboard', 'data', 'dashboard_datasource.dart'],
      DashboardPresetTemplates.datasource(projectName),
      force,
    );

    CliLogger.section('Presentation Layer');
    await _w(
      ['features', 'dashboard', 'presentation', 'bloc', 'dashboard_event.dart'],
      DashboardPresetTemplates.event(),
      force,
    );
    await _w(
      ['features', 'dashboard', 'presentation', 'bloc', 'dashboard_state.dart'],
      DashboardPresetTemplates.state(projectName),
      force,
    );
    await _w(
      ['features', 'dashboard', 'presentation', 'bloc', 'dashboard_bloc.dart'],
      DashboardPresetTemplates.bloc(projectName),
      force,
    );
    await _w(
      ['features', 'dashboard', 'presentation', 'pages', 'dashboard_page.dart'],
      DashboardPresetTemplates.page(projectName),
      force,
    );
  }

  static Future<void> _w(List<String> segments, String content, bool force) =>
      FileHelper.writeFile(FileHelper.libPath(segments), content, force: force);
}
