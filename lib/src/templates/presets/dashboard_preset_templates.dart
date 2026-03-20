class DashboardPresetTemplates {
  // ─── Datasource (Dio) ─────────────────────────────────────────────────────

  static String datasource(String project) => r'''
import 'package:dio/dio.dart';

class DashboardStats {
  final int totalOrders;
  final double totalRevenue;
  final int activeCustomers;
  final int pendingItems;
  final List<ChartDataPoint> revenueChart;
  final List<RecentActivity> recentActivity;

  const DashboardStats({
    required this.totalOrders,
    required this.totalRevenue,
    required this.activeCustomers,
    required this.pendingItems,
    required this.revenueChart,
    required this.recentActivity,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalOrders:     (json['total_orders'] as num?)?.toInt() ?? 0,
      totalRevenue:    (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      activeCustomers: (json['active_customers'] as num?)?.toInt() ?? 0,
      pendingItems:    (json['pending_items'] as num?)?.toInt() ?? 0,
      revenueChart: (json['revenue_chart'] as List<dynamic>? ?? [])
          .map((e) => ChartDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentActivity: (json['recent_activity'] as List<dynamic>? ?? [])
          .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChartDataPoint {
  final String label;
  final double value;

  const ChartDataPoint({required this.label, required this.value});

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) =>
      ChartDataPoint(
        label: json['month'] as String? ?? json['label'] as String? ?? '',
        value: (json['total'] as num?)?.toDouble() ??
               (json['value'] as num?)?.toDouble() ?? 0,
      );
}

class RecentActivity {
  final String title;
  final String subtitle;
  final String type;   // 'order' | 'customer' | 'payment' | 'alert'
  final DateTime timestamp;

  const RecentActivity({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
        title:     json['title'] as String? ?? '',
        subtitle:  json['subtitle'] as String? ?? '',
        type:      json['type'] as String? ?? 'order',
        timestamp: DateTime.parse(json['created_at'] as String),
      );
}

abstract class DashboardDatasource {
  Future<DashboardStats> getStats();
}

class DashboardDatasourceImpl implements DashboardDatasource {
  final Dio dio;

  DashboardDatasourceImpl({required this.dio});

  @override
  Future<DashboardStats> getStats() async {
    final response = await dio.get<Map<String, dynamic>>('/dashboard/stats');
    return DashboardStats.fromJson(response.data!);
  }
}
''';

  // ─── BLoC ─────────────────────────────────────────────────────────────────

  static String bloc(String project) => r'''
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardDatasource datasource;

  DashboardBloc({required this.datasource}) : super(const DashboardInitial()) {
    on<DashboardLoad>(_onLoad);
    on<DashboardRefresh>(_onRefresh);
  }

  Future<void> _onLoad(
    DashboardLoad event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    DashboardRefresh event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      emit(DashboardRefreshing((state as DashboardLoaded).stats));
    }
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<DashboardState> emit) async {
    try {
      final stats = await datasource.getStats();
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
''';

  static String event() => r'''
part of 'dashboard_bloc.dart';

sealed class DashboardEvent {
  const DashboardEvent();
}

class DashboardLoad extends DashboardEvent {
  const DashboardLoad();
}

class DashboardRefresh extends DashboardEvent {
  const DashboardRefresh();
}
''';

  static String state(String project) => r'''
part of 'dashboard_bloc.dart';

sealed class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  const DashboardLoaded(this.stats);
}

class DashboardRefreshing extends DashboardState {
  final DashboardStats stats;
  const DashboardRefreshing(this.stats);
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
}
''';

  // ─── Page ─────────────────────────────────────────────────────────────────

  static String page(String project) => r'''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/route_structure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common/loading_widget.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatelessWidget {
  static const RouteStructure route = RouteStructure(
    path: '/home',
    name: 'home',
  );

  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DashboardBloc>()..add(const DashboardLoad()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              final busy = state is DashboardRefreshing;
              return IconButton(
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: busy
                    ? null
                    : () => context
                        .read<DashboardBloc>()
                        .add(const DashboardRefresh()),
                tooltip: 'Refresh',
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) => switch (state) {
          DashboardLoading() =>
            const LoadingWidget(message: 'Loading dashboard...'),
          DashboardError(message: final msg) => _ErrorBody(message: msg),
          DashboardLoaded(stats: final s)    => _Body(stats: s),
          DashboardRefreshing(stats: final s) => _Body(stats: s),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final DashboardStats stats;
  const _Body({required this.stats});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<DashboardBloc>().add(const DashboardRefresh()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KpiGrid(stats: stats),
            const SizedBox(height: 24),
            if (stats.revenueChart.isNotEmpty) ...[
              Text('Revenue (Bulanan)', style: AppTypography.l.semiBold),
              const SizedBox(height: 12),
              _RevenueChart(data: stats.revenueChart),
              const SizedBox(height: 24),
            ],
            Text('Aktivitas Terbaru', style: AppTypography.l.semiBold),
            const SizedBox(height: 12),
            _ActivityList(items: stats.recentActivity),
          ],
        ),
      ),
    );
  }
}

// ── KPI Grid ──────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final DashboardStats stats;
  const _KpiGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiData('Total Order',  stats.totalOrders.toString(),
          Icons.receipt_long_outlined, AppColors.primary),
      _KpiData('Revenue',      Formatters.compact(stats.totalRevenue),
          Icons.payments_outlined,     AppColors.success),
      _KpiData('Pelanggan',    stats.activeCustomers.toString(),
          Icons.people_outline,        AppColors.info),
      _KpiData('Pending',      stats.pendingItems.toString(),
          Icons.pending_outlined,      AppColors.warning),
    ];

    return LayoutBuilder(
      builder: (_, c) => GridView.count(
        crossAxisCount: c.maxWidth >= 600 ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cards.map((d) => _KpiCard(data: d)).toList(),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  data.label,
                  style: AppTypography.xs.medium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 16, color: data.color),
              ),
            ],
          ),
          Text(data.value, style: AppTypography.xxl.bold),
        ],
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiData(this.label, this.value, this.icon, this.color);
}

// ── Bar Chart ─────────────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold(0.0, (m, d) => d.value > m ? d.value : m);
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((point) {
          final ratio = maxVal > 0 ? point.value / maxVal : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: LayoutBuilder(
                      builder: (_, c) => AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        height: c.maxHeight * ratio,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    point.label,
                    style: AppTypography.xs.regular.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Activity List ─────────────────────────────────────────────────────────

class _ActivityList extends StatelessWidget {
  final List<RecentActivity> items;
  const _ActivityList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Belum ada aktivitas',
            style: AppTypography.s.regular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => _ActivityTile(item: items[i]),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final RecentActivity item;
  const _ActivityTile({required this.item});

  IconData get _icon => switch (item.type) {
        'order'    => Icons.receipt_outlined,
        'customer' => Icons.person_outline,
        'payment'  => Icons.payments_outlined,
        'alert'    => Icons.warning_amber_outlined,
        _          => Icons.circle_outlined,
      };

  Color get _color => switch (item.type) {
        'order'    => AppColors.primary,
        'customer' => AppColors.info,
        'payment'  => AppColors.success,
        'alert'    => AppColors.warning,
        _          => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_icon, size: 18, color: _color),
      ),
      title: Text(item.title, style: AppTypography.s.semiBold),
      subtitle: Text(item.subtitle, style: AppTypography.xs.regular),
      trailing: Text(
        Formatters.time(item.timestamp),
        style: AppTypography.xs.regular.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<DashboardBloc>().add(const DashboardLoad()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
''';
}
