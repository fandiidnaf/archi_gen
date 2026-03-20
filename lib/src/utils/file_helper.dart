import 'dart:io';
import 'package:path/path.dart' as p;
import 'logger.dart';

class FileHelper {
  /// Writes [content] to [filePath], creating parent dirs as needed.
  /// If [force] is false and file exists, it will be skipped.
  static Future<bool> writeFile(
    String filePath,
    String content, {
    bool force = false,
  }) async {
    final file = File(filePath);
    if (file.existsSync() && !force) {
      CliLogger.skipped(filePath);
      return false;
    }
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    CliLogger.created(filePath);
    return true;
  }

  /// Creates a directory if it doesn't exist.
  static Future<void> createDir(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
  }

  /// Returns the current working directory path.
  static String get cwd => Directory.current.path;

  /// Joins path segments relative to current working directory.
  static String libPath(List<String> segments) {
    return p.joinAll([cwd, 'lib', ...segments]);
  }

  /// Check if we're inside a Flutter project (pubspec.yaml with flutter dep).
  static bool isFlutterProject() {
    final pubspec = File(p.join(cwd, 'pubspec.yaml'));
    if (!pubspec.existsSync()) return false;
    final content = pubspec.readAsStringSync();
    return content.contains('flutter:');
  }

  /// Reads pubspec.yaml project name.
  static String getProjectName() {
    final pubspec = File(p.join(cwd, 'pubspec.yaml'));
    if (!pubspec.existsSync()) return 'my_app';
    final lines = pubspec.readAsLinesSync();
    for (final line in lines) {
      if (line.startsWith('name:')) {
        return line.split(':').last.trim();
      }
    }
    return 'my_app';
  }
}
