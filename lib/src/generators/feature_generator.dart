import '../utils/file_helper.dart';
import '../utils/logger.dart';
import '../templates/feature/feature_templates.dart';
import '../templates/feature/form_templates.dart';

class FeatureGenerator {
  final String featureName; // snake_case  e.g. "product"
  final String className; // PascalCase  e.g. "Product"
  final String projectName;
  final bool withUsecase;
  final bool withDatasource;
  final bool withForm;

  const FeatureGenerator({
    required this.featureName,
    required this.className,
    required this.projectName,
    this.withUsecase = true,
    this.withDatasource = true,
    this.withForm = false,
  });

  Future<void> generate() async {
    CliLogger.section('Domain Layer');
    await _generateDomain();

    CliLogger.section('Data Layer');
    await _generateData();

    CliLogger.section('Presentation Layer');
    await _generatePresentation();
  }

  // ─── Domain ───────────────────────────────────────────────────────────────

  Future<void> _generateDomain() async {
    await _w(
      _domainPath(['entities', '${featureName}_entity.dart']),
      FeatureTemplates.entity(featureName: featureName, className: className),
    );
    await _w(
      _domainPath(['repositories', '${featureName}_repository.dart']),
      FeatureTemplates.repository(
        featureName: featureName,
        className: className,
        projectName: projectName,
      ),
    );
    if (withUsecase) {
      await _w(
        _domainPath(['usecases', 'get_${featureName}_usecase.dart']),
        FeatureTemplates.usecase(
          featureName: featureName,
          className: className,
          projectName: projectName,
        ),
      );
    }
  }

  // ─── Data ─────────────────────────────────────────────────────────────────

  Future<void> _generateData() async {
    await _w(
      _dataPath(['models', '${featureName}_model.dart']),
      FeatureTemplates.model(
        featureName: featureName,
        className: className,
        projectName: projectName,
      ),
    );
    if (withDatasource) {
      await _w(
        _dataPath(['datasources', '${featureName}_remote_datasource.dart']),
        FeatureTemplates.remoteDatasource(
          featureName: featureName,
          className: className,
          projectName: projectName,
        ),
      );
    }
    await _w(
      _dataPath(['repositories', '${featureName}_repository_impl.dart']),
      FeatureTemplates.repositoryImpl(
        featureName: featureName,
        className: className,
        projectName: projectName,
        withDatasource: withDatasource,
      ),
    );
  }

  // ─── Presentation ─────────────────────────────────────────────────────────

  Future<void> _generatePresentation() async {
    await _w(
      _presentationPath(['bloc', '${featureName}_event.dart']),
      FeatureTemplates.blocEvent(
        featureName: featureName,
        className: className,
      ),
    );
    await _w(
      _presentationPath(['bloc', '${featureName}_state.dart']),
      FeatureTemplates.blocState(
        featureName: featureName,
        className: className,
      ),
    );
    await _w(
      _presentationPath(['bloc', '${featureName}_bloc.dart']),
      FeatureTemplates.bloc(
        featureName: featureName,
        className: className,
        projectName: projectName,
        withUsecase: withUsecase,
      ),
    );
    await _w(
      _presentationPath(['pages', '${featureName}_page.dart']),
      FeatureTemplates.page(
        featureName: featureName,
        className: className,
        projectName: projectName,
      ),
    );
    if (withForm) {
      await _w(
        _presentationPath(['pages', '${featureName}_form_page.dart']),
        FormTemplates.formPage(featureName: featureName, className: className),
      );
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _w(String path, String content) =>
      FileHelper.writeFile(path, content);

  String _domainPath(List<String> s) =>
      FileHelper.libPath(['features', featureName, 'domain', ...s]);

  String _dataPath(List<String> s) =>
      FileHelper.libPath(['features', featureName, 'data', ...s]);

  String _presentationPath(List<String> s) =>
      FileHelper.libPath(['features', featureName, 'presentation', ...s]);
}
