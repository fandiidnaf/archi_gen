import 'dart:io';
import '../utils/file_helper.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';

class RemoveCommand {
  Future<void> run({
    required String featureName,
    bool skipConfirm = false,
  }) async {
    if (!FileHelper.isFlutterProject()) {
      CliLogger.error('No Flutter project found in current directory.');
      return;
    }

    final snakeName = toSnakeCase(featureName);
    final className = toPascalCase(featureName);
    final featureDir = Directory(FileHelper.libPath(['features', snakeName]));

    if (!featureDir.existsSync()) {
      CliLogger.error('Feature "$className" not found at: ${featureDir.path}');
      CliLogger.hint('Use `dart run clean_arch_gen list` to see existing features.');
      return;
    }

    // Count files to be deleted for user info
    final fileCount = featureDir
        .listSync(recursive: true)
        .whereType<File>()
        .length;

    CliLogger.section('Remove Feature: $className');
    CliLogger.warn('This will delete: ${featureDir.path}');
    CliLogger.warn('Files affected: $fileCount file(s)');
    print('');

    if (!skipConfirm) {
      stdout.write('  Are you sure? Type the feature name to confirm ($snakeName): ');
      final input = stdin.readLineSync()?.trim() ?? '';
      if (input != snakeName) {
        CliLogger.info('Aborted — input did not match "$snakeName".');
        return;
      }
    }

    await featureDir.delete(recursive: true);
    CliLogger.success('Feature "$className" removed.');
    print('');
    CliLogger.hint('Remember to also remove:');
    print('  • Registration in lib/core/di/service_locator.dart');
    print('  • Routes in lib/core/router/app_router.dart');
    print('  • Nav destination in lib/core/widgets/shell/main_shell.dart');
  }
}
