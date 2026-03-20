import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';

class ListCommand {
  Future<void> run() async {
    if (!FileHelper.isFlutterProject()) {
      CliLogger.error('No Flutter project found in current directory.');
      return;
    }

    final featuresDir = Directory(FileHelper.libPath(['features']));
    final coreDir = Directory(FileHelper.libPath(['core']));

    CliLogger.printBanner();
    print('');
    CliLogger.section('Project: ${FileHelper.getProjectName()}');
    print('');

    // ── Core status ──────────────────────────────────────────────────────────
    final coreExists = coreDir.existsSync();
    if (coreExists) {
      CliLogger.success('Core structure: initialized');
      _listCoreFiles(coreDir);
    } else {
      CliLogger.warn('Core structure: NOT initialized');
      CliLogger.hint('Run: dart run archi_gen init');
    }

    print('');

    // ── Features ─────────────────────────────────────────────────────────────
    if (!featuresDir.existsSync()) {
      CliLogger.warn('No features found.');
      CliLogger.hint('Run: dart run archi_gen feature <n>');
      return;
    }

    final features = featuresDir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList()
      ..sort();

    if (features.isEmpty) {
      CliLogger.warn('No features found.');
      CliLogger.hint('Run: dart run archi_gen feature <n>');
      return;
    }

    CliLogger.section('Features (${features.length})');
    print('');

    for (final featureName in features) {
      final featureDir =
          Directory(FileHelper.libPath(['features', featureName]));
      final className = toPascalCase(featureName);
      final info = _analyzeFeature(featureDir, featureName);

      print('  📦 $className  ($featureName)');
      for (final line in info) {
        print('      $line');
      }
      print('');
    }
  }

  List<String> _analyzeFeature(Directory dir, String featureName) {
    final result = <String>[];

    // Domain
    final entityFile = File(
        p.join(dir.path, 'domain', 'entities', '${featureName}_entity.dart'));
    final repoFile = File(p.join(
        dir.path, 'domain', 'repositories', '${featureName}_repository.dart'));
    final usecaseDir = Directory(p.join(dir.path, 'domain', 'usecases'));

    final domainItems = [
      if (entityFile.existsSync()) 'entity',
      if (repoFile.existsSync()) 'repository',
      if (usecaseDir.existsSync() && usecaseDir.listSync().isNotEmpty)
        '${usecaseDir.listSync().length} usecase(s)',
    ];
    result.add('🏛  Domain  : ${domainItems.join(', ')}');

    // Data
    final modelFile =
        File(p.join(dir.path, 'data', 'models', '${featureName}_model.dart'));
    final datasourceFile = File(p.join(
      dir.path,
      'data',
      'datasources',
      '${featureName}_remote_datasource.dart',
    ));
    final repoImplFile = File(p.join(
      dir.path,
      'data',
      'repositories',
      '${featureName}_repository_impl.dart',
    ));
    final dataItems = [
      if (modelFile.existsSync()) 'model',
      if (datasourceFile.existsSync()) 'remote_datasource',
      if (repoImplFile.existsSync()) 'repository_impl',
    ];
    result.add('🗄  Data    : ${dataItems.join(', ')}');

    // Presentation
    final blocFile = File(p.join(
      dir.path,
      'presentation',
      'bloc',
      '${featureName}_bloc.dart',
    ));
    final pagesDir = Directory(p.join(dir.path, 'presentation', 'pages'));
    final pageFiles = pagesDir.existsSync()
        ? pagesDir
            .listSync()
            .whereType<File>()
            .map((f) => p.basenameWithoutExtension(f.path))
            .toList()
        : <String>[];

    final presItems = [
      if (blocFile.existsSync()) 'bloc',
      if (pageFiles.isNotEmpty) '${pageFiles.length} page(s)',
    ];
    result.add('🖥  Presentation: ${presItems.join(', ')}');

    return result;
  }

  void _listCoreFiles(Directory coreDir) {
    final checks = {
      'router/app_router.dart': 'GoRouter',
      'di/service_locator.dart': 'GetIt DI',
      'theme/app_theme.dart': 'Theme',
      'errors/failures.dart': 'Failures',
      'usecases/usecase.dart': 'UseCase base',
      'utils/formatters.dart': 'Formatters',
      'utils/responsive.dart': 'Responsive',
    };

    for (final entry in checks.entries) {
      final file = File(p.join(coreDir.path, entry.key));
      final status = file.existsSync() ? '✓' : '✗';
      print('      $status  ${entry.value}');
    }
  }
}
