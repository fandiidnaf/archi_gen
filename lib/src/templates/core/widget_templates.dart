class WidgetTemplates {
  // ─── LoadingWidget ────────────────────────────────────────────────────────

  static String loadingWidget() => r'''
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({super.key, this.message, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
''';

  // ─── AppCard ──────────────────────────────────────────────────────────────

  static String appCard() => r'''
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool hasBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    return Material(
      color: backgroundColor ?? Theme.of(context).cardTheme.color ?? AppColors.cardBackground,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: hasBorder ? Border.all(color: AppColors.border) : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
''';

  // ─── StatusBadge ──────────────────────────────────────────────────────────

  static String statusBadge() => r'''
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Map<String, Color>? customColors;

  const StatusBadge(this.status, {super.key, this.customColors});

  Color get _color {
    final map = customColors ?? AppColors.statusColors;
    return map[status.toLowerCase()] ?? AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: .3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
''';

  // ─── EmptyState ───────────────────────────────────────────────────────────

  static String emptyState() => r'''
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(icon, size: 36, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
''';

  // ─── ConfirmDialog ────────────────────────────────────────────────────────

  static String confirmDialog() => r'''
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDangerous;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDangerous = false,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDangerous: isDangerous,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: isDangerous ? AppColors.error : AppColors.primary,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
''';

  // ─── SearchFilterBar ──────────────────────────────────────────────────────

  static String searchFilterBar() => r'''
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SearchFilterBar extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onFilter;
  final bool showFilterButton;
  final int? activeFilterCount;

  const SearchFilterBar({
    super.key,
    this.hintText,
    this.onSearch,
    this.onFilter,
    this.showFilterButton = false,
    this.activeFilterCount,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Search...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                        widget.onSearch?.call('');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) {},
          ),
        ),
        if (widget.showFilterButton) ...[
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onFilter,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Filter'),
              ),
              if ((widget.activeFilterCount ?? 0) > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.activeFilterCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
''';

  // ─── AppDataTable ─────────────────────────────────────────────────────────

  static String appDataTable() => r'''
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppDataTable<T> extends StatelessWidget {
  final List<AppDataColumn> columns;
  final List<T> rows;
  final List<DataCell> Function(T item) cellBuilder;
  final void Function(T item)? onRowTap;
  final bool isLoading;
  final String emptyMessage;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.cellBuilder,
    this.onRowTap,
    this.isLoading = false,
    this.emptyMessage = 'No data',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyMessage,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        headingRowHeight: 44,
        dividerThickness: 1,
        border: TableBorder.all(color: AppColors.border, width: 0.5),
        columns: columns
            .map(
              (c) => DataColumn(
                label: Expanded(
                  child: Text(
                    c.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                numeric: c.numeric,
              ),
            )
            .toList(),
        rows: rows
            .map(
              (item) => DataRow(
                onSelectChanged:
                    onRowTap != null ? (_) => onRowTap!(item) : null,
                cells: cellBuilder(item),
              ),
            )
            .toList(),
      ),
    );
  }
}

class AppDataColumn {
  final String label;
  final bool numeric;

  const AppDataColumn(this.label, {this.numeric = false});
}
''';

  // ─── PermissionGuard ──────────────────────────────────────────────────────

  static String permissionGuard() => r'''
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PermissionGuard extends StatelessWidget {
  final bool hasPermission;
  final Widget child;
  final Widget? fallback;
  final bool hideCompletely;

  const PermissionGuard({
    super.key,
    required this.hasPermission,
    required this.child,
    this.fallback,
    this.hideCompletely = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hasPermission) return child;
    if (hideCompletely || fallback == null) return const SizedBox.shrink();
    return fallback!;
  }
}

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You don't have permission to view this page.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
''';

  // ─── MainShell (StatefulShellBranch) ──────────────────────────────────────

  static String mainShell(String projectName) => r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation shell for mobile.
///
/// Works with StatefulShellRoute.indexedStack in app_router.dart.
/// Each branch keeps its own Navigator stack → state is preserved on tab switch.
///
/// To add a new tab:
///   1. Add _NavItem to [_items]
///   2. Add matching StatefulShellBranch in app_router.dart
///
/// The index order in [_items] MUST match the branch order in app_router.dart.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  // ── Nav items ── order must match StatefulShellBranch order in app_router ─
  static const _items = [
    _NavItem(label: 'Home',  icon: Icons.home_outlined,   activeIcon: Icons.home),
    // Add more tabs here:
    // _NavItem(label: 'Orders', icon: Icons.list_outlined,  activeIcon: Icons.list),
    // _NavItem(label: 'Profile',icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _items.length > 1
          ? NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              destinations: _items
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.activeIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // initialLocation = true: tapping the active tab goes back to root
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
''';
}
