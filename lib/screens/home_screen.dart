import 'package:expense_tracker/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_database.dart';

class AppColors {
  static const background = Color(0xFFF7F8FA);
  static const todayCard = Color(0xFF4F46E5);
  static const weekCard = Color(0xFF0D9488);
  static const alertBg = Color(0xFFFFF4E5);
  static const alertBorder = Color(0xFFF59E0B);
  static const textDark = Color(0xFF1F2937);
  static const textMuted = Color(0xFF6B7280);
  static const spendUp = Color(0xFFDC2626);
  static const spendDown = Color(0xFF16A34A);
}

const Map<String, IconData> iconMap = {
  'directions_bus_rounded': Icons.directions_bus_rounded,
  'train_rounded': Icons.train_rounded,
  'local_taxi_rounded': Icons.local_taxi_rounded,
  'local_gas_station_rounded': Icons.local_gas_station_rounded,
  'lunch_dining_rounded': Icons.lunch_dining_rounded,
  'shopping_cart_rounded': Icons.shopping_cart_rounded,
  'restaurant_rounded': Icons.restaurant_rounded,
  'shopping_bag_rounded': Icons.shopping_bag_rounded,
  'receipt_long_rounded': Icons.receipt_long_rounded,
  'movie_rounded': Icons.movie_rounded,
  'local_hospital_rounded': Icons.local_hospital_rounded,
};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool loading = true;

  double todaySpend = 0;
  double yesterdaySpend = 0;
  double weekSpend = 0;
  double lastWeekSpend = 0;
  List<Expense> todayTransactions = [];
  Map<String, Category> catById = {};
  List<String> overspendMessages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _startOfWeek(DateTime d) {
    final startOfToday = _startOfDay(d);
    return startOfToday.subtract(Duration(days: d.weekday - 1));
  }

  Future<void> _load() async {
    final repo = ref.read(expenseRepositoryProvider);
    final cats = await ref.read(categoryRepositoryProvider).fetchAll();
    catById = {for (final c in cats) c.id: c};

    final now = DateTime.now();
    final todayStart = _startOfDay(now);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = _startOfWeek(now);
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));

    final todayList = await repo.fetchRange(todayStart, now);
    final yesterdayList = await repo.fetchRange(yesterdayStart, todayStart);
    final weekList = await repo.fetchRange(weekStart, now);
    final lastWeekList = await repo.fetchRange(lastWeekStart, weekStart);

    double sum(List<Expense> l) => l.fold(0.0, (s, e) => s + e.amount);

    setState(() {
      todayTransactions = todayList;
      todaySpend = sum(todayList);
      yesterdaySpend = sum(yesterdayList);
      weekSpend = sum(weekList);
      lastWeekSpend = sum(lastWeekList);
      overspendMessages = _buildOverspendMessages(todayList, yesterdayList);
      loading = false;
    });
  }

  Map<String, double> _sumByCategory(List<Expense> list) {
    final result = <String, double>{};
    for (final e in list) {
      final cat = catById[e.categoryId];
      final parentId = cat?.parentId ?? cat?.id;
      final name = catById[parentId]?.name ?? cat?.name ?? 'Unknown';
      result[name] = (result[name] ?? 0) + e.amount;
    }
    return result;
  }

  List<String> _buildOverspendMessages(
    List<Expense> today,
    List<Expense> yesterday,
  ) {
    final todayByCat = _sumByCategory(today);
    final yesterdayByCat = _sumByCategory(yesterday);

    final messages = <MapEntry<String, double>>[];
    for (final entry in todayByCat.entries) {
      final prevAmount = yesterdayByCat[entry.key] ?? 0;
      final increase = entry.value - prevAmount;
      if (increase >= 20) messages.add(MapEntry(entry.key, increase));
    }

    messages.sort((a, b) => b.value.compareTo(a.value));
    return messages
        .map(
          (e) =>
              "You spent ₹${e.value.toStringAsFixed(0)} more on ${e.key} than yesterday.",
        )
        .toList();
  }

  double? _pctChange(double current, double previous) {
    if (previous == 0) return null;
    return ((current - previous) / previous) * 100;
  }

  bool get isOverspending {
    final dailyAvg = lastWeekSpend > 0 ? lastWeekSpend / 7 : 0;
    return dailyAvg > 0 && todaySpend > dailyAvg * 1.3;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final todayPct = _pctChange(todaySpend, yesterdaySpend);
    final weekPct = _pctChange(weekSpend, lastWeekSpend);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileRow(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSpendCard(
                        label: "Today's Spend",
                        amount: todaySpend,
                        pct: todayPct,
                        comparisonLabel: 'vs yesterday',
                        color: AppColors.todayCard,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSpendCard(
                        label: "This Week",
                        amount: weekSpend,
                        pct: weekPct,
                        comparisonLabel: 'vs last week',
                        color: AppColors.weekCard,
                      ),
                    ),
                  ],
                ),
                if (isOverspending || overspendMessages.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildOverspendAlert(),
                ],
                const SizedBox(height: 20),
                _buildTransactionsHeader(),
                const SizedBox(height: 8),
                if (todayTransactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No expenses yet today',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  ...todayTransactions.map(_buildTransactionTile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow() {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${now.day} ${months[now.month - 1]} ${now.year}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            Text(
              days[now.weekday - 1],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpendCard({
    required String label,
    required double amount,
    required double? pct,
    required String comparisonLabel,
    required Color color,
  }) {
    final hasComparison = pct != null;
    final isUp = hasComparison && pct > 0;
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hasComparison)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${pct.abs().toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    comparisonLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ),
              ],
            )
          else
            const Text(
              'No data yet',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildOverspendAlert() {
    if (overspendMessages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.alertBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.alertBorder.withOpacity(0.4)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.alertBorder,
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "You're spending more than usual today.",
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textDark,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.alertBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.alertBorder.withOpacity(0.4)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.alertBorder,
            size: 22,
          ),
          title: Text(
            overspendMessages.length == 1
                ? overspendMessages.first
                : 'Spending more than usual in ${overspendMessages.length} categories',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textDark,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: overspendMessages.length == 1
              ? []
              : overspendMessages
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          m,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textDark,
                            height: 1.3,
                          ),
                        ),
                      ),
                    )
                    .toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Today's Transactions",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Text(
            'View all',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.todayCard,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(Expense tx) {
    final cat = catById[tx.categoryId];
    final parentCat = cat?.parentId != null ? catById[cat!.parentId] : cat;
    final icon = iconMap[cat?.icon] ?? Icons.category_rounded;
    final time = TimeOfDay.fromDateTime(tx.spentAt).format(context);

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.spendUp,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete expense?'),
          content: Text(
            'Remove ₹${tx.amount.toStringAsFixed(0)} for ${parentCat?.name ?? ''}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) async {
        await ref.read(expenseRepositoryProvider).deleteExpense(tx.id);
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.todayCard.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.todayCard),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parentCat?.name ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '${cat?.name ?? ''} · $time',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${tx.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
