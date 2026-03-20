class CliLogger {
  // ANSI color codes
  static const _reset = '\x1B[0m';
  static const _bold = '\x1B[1m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';
  static const _cyan = '\x1B[36m';
  static const _gray = '\x1B[90m';
  static const _magenta = '\x1B[35m';

  static void printBanner() {
    print('$_cyan$_bold');
    print('  ██████╗██╗     ███████╗ █████╗ ███╗   ██╗');
    print(' ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║');
    print(' ██║     ██║     █████╗  ███████║██╔██╗ ██║');
    print(' ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║');
    print(' ╚██████╗███████╗███████╗██║  ██║██║ ╚████║');
    print('  ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝');
    print('$_reset$_gray  arch generator — flutter clean architecture CLI$_reset');
  }

  static void success(String message) {
    print('$_green  ✓  $message$_reset');
  }

  static void error(String message) {
    print('$_red  ✗  $message$_reset');
  }

  static void info(String message) {
    print('$_cyan  ●  $message$_reset');
  }

  static void warn(String message) {
    print('$_yellow  ⚠  $message$_reset');
  }

  static void hint(String message) {
    print('$_gray  →  $message$_reset');
  }

  static void section(String title) {
    print('');
    print('$_magenta$_bold  [$title]$_reset');
  }

  static void created(String path) {
    print('$_green  +  $_gray$path$_reset');
  }

  static void skipped(String path) {
    print('$_yellow  ~  $_gray$path (already exists, skipped)$_reset');
  }

  static void divider() {
    print('$_gray  ─────────────────────────────────────$_reset');
  }
}
