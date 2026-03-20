import '../utils/file_helper.dart';
import '../utils/logger.dart';
import '../templates/core/core_templates.dart';
import '../templates/core/network_templates.dart';
import '../templates/core/widget_templates.dart';

class CoreGenerator {
  final String projectName;
  final bool force;

  const CoreGenerator({required this.projectName, this.force = false});

  Future<void> generate() async {
    CliLogger.section('Core / Errors & UseCases');
    await _w(['core', 'errors', 'failures.dart'],    CoreTemplates.failures());
    await _w(['core', 'usecases', 'usecase.dart'],    CoreTemplates.usecase());

    CliLogger.section('Core / Constants');
    await _w(['core', 'constants', 'app_constants.dart'], CoreTemplates.appConstants());

    CliLogger.section('Core / Extensions');
    await _w(['core', 'extensions', 'num_ext.dart'], CoreTemplates.numExt());

    CliLogger.section('Core / Network');
    await _w(['core', 'network', 'dio_client.dart'],
        NetworkTemplates.dioClient());
    await _w(['core', 'network', 'token_storage.dart'],
        NetworkTemplates.tokenStorage());
    await _w(['core', 'network', 'interceptors', 'auth_interceptor.dart'],
        NetworkTemplates.authInterceptor());
    await _w(['core', 'network', 'interceptors', 'error_interceptor.dart'],
        NetworkTemplates.errorInterceptor());
    await _w(['core', 'network', 'interceptors', 'logging_interceptor.dart'],
        NetworkTemplates.loggingInterceptor());

    CliLogger.section('Core / DI & Router');
    await _w(['core', 'di', 'service_locator.dart'],     CoreTemplates.serviceLocator(projectName));
    await _w(['core', 'router', 'app_router.dart'],      CoreTemplates.appRouter(projectName));
    await _w(['core', 'router', 'route_structure.dart'], CoreTemplates.routeStructure());

    CliLogger.section('Core / Theme');
    await _w(['core', 'theme', 'app_colors.dart'],     CoreTemplates.appColors());
    await _w(['core', 'theme', 'app_typography.dart'], CoreTemplates.appTypography());
    await _w(['core', 'theme', 'app_theme.dart'],      CoreTemplates.appTheme());

    CliLogger.section('Core / Utils');
    await _w(['core', 'utils', 'app_logger.dart'],       CoreTemplates.appLogger());
    await _w(['core', 'utils', 'formatters.dart'],       CoreTemplates.formatters());
    await _w(['core', 'utils', 'responsive.dart'],       CoreTemplates.responsive());
    await _w(['core', 'utils', 'paginated_result.dart'], CoreTemplates.paginatedResult());

    CliLogger.section('Core / Mixins');
    await _w(['core', 'mixins', 'helper_mixin.dart'], CoreTemplates.helperMixin());

    CliLogger.section('Core / Widgets — Common');
    await _w(['core', 'widgets', 'common', 'loading_widget.dart'],    WidgetTemplates.loadingWidget());
    await _w(['core', 'widgets', 'common', 'app_card.dart'],          WidgetTemplates.appCard());
    await _w(['core', 'widgets', 'common', 'status_badge.dart'],      WidgetTemplates.statusBadge());
    await _w(['core', 'widgets', 'common', 'search_filter_bar.dart'], WidgetTemplates.searchFilterBar());
    await _w(['core', 'widgets', 'common', 'app_data_table.dart'],    WidgetTemplates.appDataTable());
    await _w(['core', 'widgets', 'common', 'permission_guard.dart'],  WidgetTemplates.permissionGuard());
    await _w(['core', 'widgets', 'common', 'empty_state.dart'],       WidgetTemplates.emptyState());
    await _w(['core', 'widgets', 'common', 'confirm_dialog.dart'],    WidgetTemplates.confirmDialog());

    CliLogger.section('Core / Widgets — Shell');
    await _w(['core', 'widgets', 'shell', 'main_shell.dart'], WidgetTemplates.mainShell(projectName));

    CliLogger.section('App Entry Point');
    await _w(['main.dart'], CoreTemplates.mainDart(projectName));
  }

  Future<void> _w(List<String> segments, String content) =>
      FileHelper.writeFile(FileHelper.libPath(segments), content, force: force);
}
