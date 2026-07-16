import 'package:expense_tracker/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/local_database.dart';
import 'home_screen.dart';

enum Period { day, week, month }

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});
  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  Period period = Period.day;
  bool loading = true;
  List<Expense> current = [];
  List<Expense> previous = [];
  Map<String, Category> catById = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  (DateTime, DateTime, DateTime, DateTime) _ranges() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case Period.day:
        final yesterday = today.subtract(const Duration(days: 1));
        return (today, now, yesterday, today);
      case Period.week:
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        final lastWeekStart = weekStart.subtract(const Duration(days: 7));
        return (weekStart, now, lastWeekStart, weekStart);
      case Period.month:
        final monthStart = DateTime(now.year, now.month, 1);
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        return (monthStart, now, lastMonthStart, monthStart);
    }
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final repo = ref.read(expenseRepositoryProvider);
    final cats = await ref.read(categoryRepositoryProvider).fetchAll();
    catById = {for (final c in cats) c.id: c};

    final (curStart, curEnd, prevStart, prevEnd) = _ranges();
    current = await repo.fetchRange(curStart, curEnd);
    previous = await repo.fetchRange(prevStart, prevEnd);

    setState(() => loading = false);
  }

  Map<String, double> _byCategory(List<Expense> list) {
    final result = <String, double>{};
    for (final e in list) {
      final cat = catById[e.categoryId];
      final parentId = cat?.parentId ?? cat?.id ?? 'unknown';
      final parentName = catById[parentId]?.name ?? 'Unknown';
      result[parentName] = (result[parentName] ?? 0) + e.amount;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final curByCat = _byCategory(current);
    final prevByCat = _byCategory(previous);
    final curTotal = curByCat.values.fold(0.0, (a, b) => a + b);
    final prevTotal = prevByCat.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insights',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _buildSegmentedControl(),
              const SizedBox(height: 20),
              _buildComparisonBars(curTotal, prevTotal),
              const SizedBox(height: 24),
              const Text(
                'By Category',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              if (curByCat.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No expenses in this period',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else ...[
                _buildDonutChart(curByCat),
                const SizedBox(height: 16),
                ..._buildCategoryLegend(curByCat, prevByCat, curTotal),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Row(
      children: Period.values.map((p) {
        final isSelected = period == p;
        final label = p == Period.day
            ? 'Day'
            : p == Period.week
            ? 'Week'
            : 'Month';
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => period = p);
              _load();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.todayCard : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComparisonBars(double curTotal, double prevTotal) {
    final maxVal = [curTotal, prevTotal, 1.0].reduce((a, b) => a > b ? a : b);
    final prevLabel = period == Period.day
        ? 'Yesterday'
        : period == Period.week
        ? 'Last week'
        : 'Last month';
    final curLabel = period == Period.day
        ? 'Today'
        : period == Period.week
        ? 'This week'
        : 'This month';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            maxY: maxVal * 1.2,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      value == 0 ? prevLabel : curLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: prevTotal,
                    color: AppColors.textMuted.withOpacity(0.3),
                    width: 40,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: curTotal,
                    color: AppColors.todayCard,
                    width: 40,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _palette = [
    AppColors.todayCard,
    AppColors.weekCard,
    Color(0xFFF59E0B),
    Color(0xFFDC2626),
    Color(0xFF8B5CF6),
    Color(0xFF16A34A),
  ];

  Widget _buildDonutChart(Map<String, double> data) {
    final entries = data.entries.toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 180,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 50,
            sections: List.generate(entries.length, (i) {
              return PieChartSectionData(
                value: entries[i].value,
                color: _palette[i % _palette.length],
                title: '',
                radius: 45,
              );
            }),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryLegend(
    Map<String, double> data,
    Map<String, double> prevData,
    double total,
  ) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return List.generate(entries.length, (i) {
      final pct = total > 0 ? (entries[i].value / total * 100) : 0;
      final prevVal = prevData[entries[i].key] ?? 0;
      final delta = _pctDelta(entries[i].value, prevVal);

      return InkWell(
        onTap: () => _showSubcategoryDrilldown(entries[i].key),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _palette[i % _palette.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entries[i].key,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (delta != null) ...[
                Icon(
                  delta >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 12,
                  color: delta >= 0 ? AppColors.spendUp : AppColors.spendDown,
                ),
                Text(
                  '${delta.abs().toStringAsFixed(0)}%  ',
                  style: TextStyle(
                    fontSize: 11,
                    color: delta >= 0 ? AppColors.spendUp : AppColors.spendDown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              Text(
                '₹${entries[i].value.toStringAsFixed(0)}  ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      );
    });
  }

  double? _pctDelta(double current, double previous) {
    if (previous == 0) return null;
    return ((current - previous) / previous) * 100;
  }

  void _showSubcategoryDrilldown(String parentName) {
    final parentCat = catById.values.firstWhere(
      (c) => c.name == parentName && c.parentId == null,
      orElse: () => catById.values.first,
    );

    final subExpenses = current.where((e) {
      final cat = catById[e.categoryId];
      return cat?.parentId == parentCat.id ||
          (cat?.id == parentCat.id && cat?.parentId == null);
    }).toList();

    final bySub = <String, double>{};
    for (final e in subExpenses) {
      final cat = catById[e.categoryId];
      final label = (cat?.parentId == null)
          ? 'General'
          : (cat?.name ?? 'Unknown');
      bySub[label] = (bySub[label] ?? 0) + e.amount;
    }
    final total = bySub.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = bySub.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              parentName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${total.toStringAsFixed(0)} total',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            if (sortedEntries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No subcategory data',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ...sortedEntries.map((e) {
                final pct = total > 0 ? e.value / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '₹${e.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: AppColors.background,
                          color: AppColors.todayCard,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
