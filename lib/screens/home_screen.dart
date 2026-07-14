import 'package:flutter/material.dart';

// ── Palette ────────────────────────────────────────────────────────────
// Keeping this in one place so it's trivial to swap for a Theme later.
class AppColors {
  static const background = Color(0xFFF7F8FA);
  static const todayCard = Color(0xFF4F46E5); // indigo
  static const weekCard = Color(0xFF0D9488); // teal
  static const alertBg = Color(0xFFFFF4E5);
  static const alertBorder = Color(0xFFF59E0B);
  static const textDark = Color(0xFF1F2937);
  static const textMuted = Color(0xFF6B7280);
  static const spendUp = Color(0xFFDC2626); // spending MORE = bad = red
  static const spendDown = Color(0xFF16A34A); // spending LESS = good = green
}

// Swap for GoogleFonts.poppins()/inter() once you add the google_fonts
// package — kept as system font here so this compiles standalone.
const _fontFamily = 'Roboto';

class Transaction {
  final String category;
  final String subcategory;
  final double amount;
  final String time;
  final IconData icon;

  Transaction({
    required this.category,
    required this.subcategory,
    required this.amount,
    required this.time,
    required this.icon,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Mock data — replace with Riverpod providers reading from Drift ──
  final double todaySpend = 850;
  final double todayVsYesterdayPct = 18; // +18%
  final double weekSpend = 4200;
  final double weekVsLastWeekPct = -6; // -6%

  final bool isOverspending = true; // drive this from a real threshold check

  final List<Transaction> todayTransactions = [
    Transaction(
      category: 'Travelling',
      subcategory: 'Bus',
      amount: 40,
      time: '9:02 AM',
      icon: Icons.directions_bus_rounded,
    ),
    Transaction(
      category: 'Food',
      subcategory: 'Lunch',
      amount: 180,
      time: '1:15 PM',
      icon: Icons.lunch_dining_rounded,
    ),
    Transaction(
      category: 'Shopping',
      subcategory: 'Groceries',
      amount: 630,
      time: '6:40 PM',
      icon: Icons.shopping_bag_rounded,
    ),
  ];

  // Smart suggestion — in the real app this flips true when the
  // time-bucket match (see the algorithm doc) finds a repeating pattern.
  bool showSmartSuggestion = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileRow(),
                  const SizedBox(height: 24),
                  _buildSpendCards(),
                  const SizedBox(height: 20),
                  if (isOverspending) _buildOverspendAlert(),
                  if (isOverspending) const SizedBox(height: 20),
                  _buildTransactionsHeader(),
                  const SizedBox(height: 8),
                  ...todayTransactions.map(_buildTransactionTile),
                ],
              ),
            ),
            if (showSmartSuggestion) _buildSmartSuggestionCard(),
          ],
        ),
      ),
    );
  }

  // ── Profile / date row ────────────────────────────────────────────
  Widget _buildProfileRow() {
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
          children: const [
            Text(
              "15 June 2026",
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            Text(
              "Wednesday",
              style: TextStyle(
                fontFamily: _fontFamily,
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

  // ── Today / Week spend cards ──────────────────────────────────────
  Widget _buildSpendCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildSpendCard(
            label: "Today's Spend",
            amount: todaySpend,
            comparisonPct: todayVsYesterdayPct,
            comparisonLabel: 'vs yesterday',
            color: AppColors.todayCard,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildSpendCard(
            label: "This Week",
            amount: weekSpend,
            comparisonPct: weekVsLastWeekPct,
            comparisonLabel: 'vs last week',
            color: AppColors.weekCard,
          ),
        ),
      ],
    );
  }

  Widget _buildSpendCard({
    required String label,
    required double amount,
    required double comparisonPct,
    required String comparisonLabel,
    required Color color,
  }) {
    final isUp = comparisonPct > 0;
    final arrowIcon = isUp
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

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
              fontFamily: _fontFamily,
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          // Small +/- % badge — deliberately understated per the brief.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(arrowIcon, size: 11, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      '${comparisonPct.abs().toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: _fontFamily,
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
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Overspend alert ────────────────────────────────────────────────
  Widget _buildOverspendAlert() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.alertBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.alertBorder.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.alertBorder,
            size: 22,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "You're spending more than usual today — 18% above your daily average.",
              style: TextStyle(
                fontFamily: _fontFamily,
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

  // ── Transactions list ──────────────────────────────────────────────
  Widget _buildTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Today's Transactions",
          style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        TextButton(
          onPressed: () {
            // Navigate to full transactions list screen.
          },
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Text(
            'View all',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.todayCard,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(Transaction tx) {
    return Container(
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
            child: Icon(tx.icon, size: 20, color: AppColors.todayCard),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.category,
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${tx.subcategory} · ${tx.time}',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
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
              fontFamily: _fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating smart suggestion ─────────────────────────────────────
  // Positioned above the bottom nav, inside thumb reach. The confirm
  // button sits on the trailing edge so a right-hand thumb lands on it
  // without stretching.
  Widget _buildSmartSuggestionCard() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 90, // sits just above the bottom nav bar
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
            const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Bus fare · ₹40\nSame time as yesterday?',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 12.5,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => showSmartSuggestion = false),
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
              onTap: () {
                // Insert into Drift with spent_at = now(), synced = false.
                setState(() => showSmartSuggestion = false);
              },
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
}
