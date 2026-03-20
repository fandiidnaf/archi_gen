import 'package:args/args.dart';
import 'commands/init_command.dart';
import 'commands/feature_command.dart';
import 'commands/preset_command.dart';
import 'commands/list_command.dart';
import 'commands/remove_command.dart';
import 'commands/doctor_command.dart';
import 'utils/logger.dart';

class CleanArchCli {
  Future<void> run(List<String> args) async {
    final parser = ArgParser()
      ..addCommand('init')
      ..addCommand('feature')
      ..addCommand('preset')
      ..addCommand('list')
      ..addCommand('remove')
      ..addCommand('doctor')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage')
      ..addFlag('version', abbr: 'v', negatable: false, help: 'Show version');

    // ── feature ───────────────────────────────────────────────────────────
    parser.commands['feature']!
      ..addFlag('help', abbr: 'h', negatable: false)
      ..addFlag('no-usecase', negatable: false, help: 'Skip domain/usecases/')
      ..addFlag(
        'no-datasource',
        negatable: false,
        help: 'Skip data/datasources/',
      )
      ..addFlag(
        'with-form',
        negatable: false,
        help: 'Generate a create/edit form page',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Overwrite existing files',
      );

    // ── init ──────────────────────────────────────────────────────────────
    parser.commands['init']!
      ..addFlag('help', abbr: 'h', negatable: false)
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Overwrite existing files',
      )
      ..addFlag(
        'no-install',
        negatable: false,
        help: 'Skip running flutter pub add',
      );

    // ── preset ────────────────────────────────────────────────────────────
    parser.commands['preset']!
      ..addFlag('help', abbr: 'h', negatable: false)
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Overwrite existing files',
      );

    // ── list + doctor ─────────────────────────────────────────────────────
    parser.commands['list']!.addFlag('help', abbr: 'h', negatable: false);
    parser.commands['doctor']!.addFlag('help', abbr: 'h', negatable: false);

    // ── remove ────────────────────────────────────────────────────────────
    parser.commands['remove']!
      ..addFlag('help', abbr: 'h', negatable: false)
      ..addFlag('yes', abbr: 'y', negatable: false, help: 'Skip confirmation');

    ArgResults results;
    try {
      results = parser.parse(args);
    } catch (e) {
      CliLogger.error('Invalid arguments: $e');
      _printUsage(parser);
      return;
    }

    if (results['version'] as bool) {
      CliLogger.info('clean_arch_gen v0.4.0');
      return;
    }

    if (results['help'] as bool || results.command == null) {
      _printUsage(parser);
      return;
    }

    switch (results.command!.name) {
      case 'init':
        if (results.command!['help'] as bool) {
          _printInitUsage();
          return;
        }
        await InitCommand().run(
          force: results.command!['force'] as bool,
          injectDeps: !(results.command!['no-install'] as bool),
        );

      case 'feature':
        if (results.command!['help'] as bool) {
          _printFeatureUsage();
          return;
        }
        final rest = results.command!.rest;
        if (rest.isEmpty) {
          CliLogger.error('Feature name is required.');
          CliLogger.hint('Usage: dart run clean_arch_gen feature <name>');
          return;
        }
        await FeatureCommand().run(
          featureName: rest.first,
          withUsecase: !(results.command!['no-usecase'] as bool),
          withDatasource: !(results.command!['no-datasource'] as bool),
          withForm: results.command!['with-form'] as bool,
        );

      case 'preset':
        if (results.command!['help'] as bool) {
          _printPresetUsage();
          return;
        }
        final rest = results.command!.rest;
        if (rest.isEmpty) {
          CliLogger.error('Preset name is required.');
          CliLogger.hint('Available: auth, dashboard');
          return;
        }
        await PresetCommand().run(
          presetName: rest.first,
          force: results.command!['force'] as bool,
        );

      case 'list':
        await ListCommand().run();

      case 'remove':
        if (results.command!['help'] as bool) {
          _printRemoveUsage();
          return;
        }
        final rest = results.command!.rest;
        if (rest.isEmpty) {
          CliLogger.error('Feature name is required.');
          CliLogger.hint('Usage: dart run clean_arch_gen remove <name>');
          return;
        }
        await RemoveCommand().run(
          featureName: rest.first,
          skipConfirm: results.command!['yes'] as bool,
        );

      case 'doctor':
        await DoctorCommand().run();

      default:
        CliLogger.error('Unknown command: ${results.command!.name}');
        _printUsage(parser);
    }
  }

  // ─── Help ─────────────────────────────────────────────────────────────────

  void _printUsage(ArgParser parser) {
    CliLogger.printBanner();
    print('');
    print('Usage: dart run clean_arch_gen <command> [options]');
    print('');
    print('Commands:');
    print(
      '  init                   Generate core structure + run flutter pub add',
    );
    print(
      '  feature <name>         Generate a feature (domain/data/presentation)',
    );
    print('  preset  <name>         Generate a pre-built feature preset');
    print('  list                   Show all features and core status');
    print(
      '  remove  <name>         Delete a feature folder (with confirmation)',
    );
    print(
      '  doctor                 Diagnose deps, core files, route registration',
    );
    print('');
    print('Presets:');
    print(
      '  auth        Login page, ProfilePage, AuthBloc, 3 usecases, Dio datasource',
    );
    print('  dashboard   KPI cards, bar chart, activity feed, DashboardBloc');
    print('');
    print('Global options:');
    print(parser.usage);
    print('');
    print('Examples:');
    print('  dart run clean_arch_gen init');
    print('  dart run clean_arch_gen feature product --with-form');
    print('  dart run clean_arch_gen feature analytics --no-datasource');
    print('  dart run clean_arch_gen preset auth');
    print('  dart run clean_arch_gen doctor');
    print('  dart run clean_arch_gen remove old_feature -y');
  }

  void _printInitUsage() {
    print('Usage: dart run clean_arch_gen init [options]');
    print('');
    print('Generates lib/core/ + lib/main.dart.');
    print('Runs `flutter pub add <deps>` automatically.');
    print('');
    print('Options:');
    print('  -f, --force       Overwrite existing files');
    print('      --no-install  Skip running flutter pub add');
    print('  -h, --help        Show this help');
  }

  void _printFeatureUsage() {
    print('Usage: dart run clean_arch_gen feature <name> [options]');
    print('');
    print(
      'Generates lib/features/<name>/ with domain / data / presentation layers.',
    );
    print('Backend: Dio (HTTP REST). All datasources use Dio.');
    print('');
    print('Options:');
    print('  --with-form       Also generate a create/edit form page');
    print('  --no-usecase      Skip domain/usecases/');
    print('  --no-datasource   Skip data/datasources/');
    print('  -f, --force       Overwrite existing files');
    print('  -h, --help        Show this help');
    print('');
    print('Examples:');
    print('  dart run clean_arch_gen feature invoice --with-form');
    print(
      '  dart run clean_arch_gen feature config --no-datasource --no-usecase',
    );
  }

  void _printPresetUsage() {
    print('Usage: dart run clean_arch_gen preset <name> [options]');
    print('');
    print('Available presets:');
    print('  auth        Login page, Profile page, AuthBloc,');
    print(
      '              signIn/signOut/getCurrentProfile usecases, Dio datasource',
    );
    print('');
    print('  dashboard   KPI card grid (4 cards), animated bar chart,');
    print('              activity feed, DashboardBloc, Dio datasource');
    print('');
    print('Options:');
    print('  -f, --force   Overwrite existing files');
    print('  -h, --help    Show this help');
  }

  void _printRemoveUsage() {
    print('Usage: dart run clean_arch_gen remove <name> [options]');
    print('');
    print(
      'Deletes lib/features/<name>/ after typing the feature name to confirm.',
    );
    print('');
    print('Options:');
    print('  -y, --yes   Skip confirmation prompt');
    print('  -h, --help  Show this help');
  }
}
