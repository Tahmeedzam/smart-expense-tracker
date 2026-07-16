import 'package:expense_tracker/providers/repository_providers.dart';
import 'package:expense_tracker/screens/analysis_screen.dart';
import 'package:expense_tracker/screens/category_screen.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_database.dart';
import '../widgets/add_expense_sheet.dart';

class BottomNavbar extends ConsumerStatefulWidget {
  const BottomNavbar({super.key});
  @override
  ConsumerState<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends ConsumerState<BottomNavbar> {
  int _currentIndex = 0;
  Expense? suggestion;
  Category? suggestionCat;

  final List<Widget> _screens = const [
    HomeScreen(),
    AnalysisScreen(),
    CategoryScreen(),
    ProfileScreen(),
  ];

  Future<void> _seedTestSuggestionData() async {
    final repo = ref.read(expenseRepositoryProvider);
    final now = DateTime.now();

    await repo.add(
      id: 'test_1',
      categoryId: 'cat_travel_bus',
      amount: 40,
      spentAt: now.subtract(const Duration(days: 1)),
    );

    await repo.add(
      id: 'test_2',
      categoryId: 'cat_travel_bus',
      amount: 40,
      spentAt: now.subtract(const Duration(days: 2)),
    );
  }

  @override
  void initState() {
    super.initState();
    ref.read(expenseRepositoryProvider).syncPending();
    _checkSmartSuggestion();
  }

  Future<void> _checkSmartSuggestion() async {
    final now = DateTime.now();
    final matches = await ref
        .read(expenseRepositoryProvider)
        .fetchSameTimeWindow(
          hour: now.hour,
          toleranceMinutes: 45,
          lookbackDays: 7,
        );

    if (matches.isEmpty) return;

    final byCategory = <String, List<Expense>>{};
    for (final e in matches) {
      byCategory.putIfAbsent(e.categoryId, () => []).add(e);
    }

    MapEntry<String, List<Expense>>? best;
    for (final entry in byCategory.entries) {
      if (entry.value.length < 2) continue;
      if (best == null || entry.value.length > best!.value.length) best = entry;
    }
    if (best == null) return;

    final cats = await ref.read(categoryRepositoryProvider).fetchAll();
    final catMap = {for (final c in cats) c.id: c};
    final mostRecent = best!.value.reduce(
      (a, b) => a.spentAt.isAfter(b.spentAt) ? a : b,
    );

    if (!mounted) return;
    setState(() {
      suggestion = mostRecent;
      suggestionCat = catMap[mostRecent.categoryId];
    });
  }

  Future<void> _acceptSuggestion() async {
    if (suggestion == null) return;
    final repo = ref.read(expenseRepositoryProvider);
    await repo.add(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      categoryId: suggestion!.categoryId,
      amount: suggestion!.amount,
      note: suggestion!.note,
      spentAt: DateTime.now(),
    );
    setState(() => suggestion = null);
  }

  void _openAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          if (suggestion != null) _buildSuggestionCard(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseSheet,
        backgroundColor: AppColors.todayCard,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSuggestionCard() {
    final icon = iconMap[suggestionCat?.icon] ?? Icons.category_rounded;
    return Positioned(
      left: 20,
      right: 20,
      bottom: 90,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.textDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${suggestionCat?.name ?? 'Expense'} · ₹${suggestion!.amount.toStringAsFixed(0)}\nSame time as before?',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => suggestion = null),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white54,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _acceptSuggestion,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.textDark,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 8,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(icon: Icons.home_rounded, label: 'Home', index: 0),
            _navItem(
              icon: Icons.pie_chart_rounded,
              label: 'Analysis',
              index: 1,
            ),
            const SizedBox(width: 40),
            _navItem(icon: Icons.category_rounded, label: 'Category', index: 2),
            _navItem(icon: Icons.person_rounded, label: 'Profile', index: 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.todayCard : AppColors.textMuted;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
