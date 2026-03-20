import 'dart:io';
import 'package:path/path.dart' as p;
import '../generators/core_generator.dart';
import '../utils/file_helper.dart';
import '../utils/logger.dart';

const List<String> _requiredDeps = [
  'dio',
  'equatable',
  'flutter_bloc',
  'flutter_secure_storage',
  'fpdart',
  'fresh_dio',
  'get_it',
  'go_router',
  'google_fonts',
  'intl',
  'pretty_dio_logger',
];

class InitCommand {
  Future<void> run({bool force = false, bool injectDeps = true}) async {
    CliLogger.printBanner();
    print('');

    if (!FileHelper.isFlutterProject()) {
      CliLogger.error('No Flutter project found in current directory.');
      CliLogger.hint(
        'Run this inside your Flutter project root (where pubspec.yaml is).',
      );
      return;
    }

    final projectName = FileHelper.getProjectName();
    CliLogger.info('Project: $projectName');
    CliLogger.divider();

    CliLogger.section('Generating Core Structure');
    final generator = CoreGenerator(projectName: projectName, force: force);
    await generator.generate();

    if (injectDeps) {
      CliLogger.section('Installing Dependencies');
      await _installDependencies();
    } else {
      _printManualDeps();
    }

    CliLogger.section('Formatting Generated Files');
    await _runDartFormat();

    CliLogger.divider();
    CliLogger.success('Initialization complete!');
    print('');
    CliLogger.hint('Next steps:');
    print(
        '  1. Update AppConstants.baseUrl in lib/core/constants/app_constants.dart');
    print('  2. dart run clean_arch_gen feature <your_feature>');
    print('  3. dart run clean_arch_gen preset auth  (optional)');
    print('');
  }

  Future<void> _installDependencies() async {
    CliLogger.info('Running flutter pub add ...');
    final result = await Process.run(
      'flutter',
      ['pub', 'add', ..._requiredDeps],
      workingDirectory: FileHelper.cwd,
      runInShell: true,
    );
    if (result.exitCode == 0) {
      CliLogger.success('Dependencies installed');
    } else {
      CliLogger.error('Failed installing dependencies — run manually:');
      _printManualDeps();
    }
  }

  Future<void> _runDartFormat() async {
    final libPath = p.join(FileHelper.cwd, 'lib');
    final result = await Process.run(
      'dart',
      ['format', libPath],
      workingDirectory: FileHelper.cwd,
      runInShell: true,
    );
    if (result.exitCode == 0) {
      CliLogger.success('dart format done');
    } else {
      CliLogger.warn('dart format failed — run manually: dart format lib/');
    }
  }

  void _printManualDeps() {
    print('');
    print('  Run:');
    print('  flutter pub add ${_requiredDeps.join(' ')}');
    print('');
  }
}
