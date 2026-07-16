import 'package:expense_tracker/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/local_database.dart';
import '../screens/home_screen.dart'; // AppColors

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key});
  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  List<Category> allCats = [];
  Category? selectedParent;
  Category? selectedSub;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(categoryRepositoryProvider).fetchAll().then((c) {
      setState(() => allCats = c);
    });
  }

  List<Category> get parents =>
      allCats.where((c) => c.parentId == null).toList();
  List<Category> get subs => selectedParent == null
      ? []
      : allCats.where((c) => c.parentId == selectedParent!.id).toList();

  Future<void> _save() async {
    if (selectedParent == null || amountCtrl.text.isEmpty) return;
    setState(() => saving = true);
    final catId = selectedSub?.id ?? selectedParent!.id;
    await ref
        .read(expenseRepositoryProvider)
        .add(
          id: const Uuid().v4(),
          categoryId: catId,
          amount: double.parse(amountCtrl.text),
          note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
          spentAt: DateTime.now(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
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
              const Text(
                'Add Expense',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  border: InputBorder.none,
                  hintText: '0',
                ),
              ),
              const Divider(height: 24),
              const Text(
                'Category',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: parents.map((c) {
                  final isSel = selectedParent?.id == c.id;
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: isSel,
                    selectedColor: AppColors.todayCard,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.textDark,
                      fontSize: 12.5,
                    ),
                    onSelected: (_) => setState(() {
                      selectedParent = c;
                      selectedSub = null;
                    }),
                  );
                }).toList(),
              ),
              if (subs.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Subcategory',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subs.map((c) {
                    final isSel = selectedSub?.id == c.id;
                    return ChoiceChip(
                      label: Text(c.name),
                      selected: isSel,
                      selectedColor: AppColors.weekCard,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textDark,
                        fontSize: 12.5,
                      ),
                      onSelected: (_) => setState(() => selectedSub = c),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.todayCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Expense',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
