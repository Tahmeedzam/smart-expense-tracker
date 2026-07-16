import 'package:drift/drift.dart';
import 'package:expense_tracker/data/expense_repository.dart';
import 'package:expense_tracker/data/local_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(db.close);
  return db;
});

final categoryRepositoryProvider = Provider<LocalCategoryRepository>((ref) {
  return LocalCategoryRepository(ref.watch(localDatabaseProvider));
});

final expenseRepositoryProvider = Provider<LocalExpenseRepository>((ref) {
  return LocalExpenseRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(remoteExpenseRepositoryProvider),
  );
});

final remoteExpenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

class LocalCategoryRepository {
  final LocalDatabase _db;
  LocalCategoryRepository(this._db);

  Future<List<Category>> fetchAll() => _db.getAllCategories();

  Future<void> add({
    required String id,
    String? parentId,
    required String name,
    String? icon,
    String? color,
  }) {
    return _db.insertCategory(
      CategoriesCompanion.insert(
        id: id,
        parentId: Value(parentId),
        name: name,
        icon: Value(icon),
        color: Value(color),
      ),
    );
  }
}

class LocalExpenseRepository {
  final LocalDatabase _db;
  final ExpenseRepository _remote;

  LocalExpenseRepository(this._db, this._remote);

  Future<void> add({
    required String id,
    required String categoryId,
    required double amount,
    String? note,
    required DateTime spentAt,
  }) async {
    await _db.insertExpense(
      ExpensesCompanion.insert(
        id: id,
        categoryId: categoryId,
        amount: amount,
        note: Value(note),
        spentAt: spentAt,
      ),
    );

    try {
      await _remote.insert(
        ExpenseModel(
          id: id,
          categoryId: categoryId,
          amount: amount,
          note: note,
          spentAt: spentAt,
        ),
      );
      await _db.markSynced(id);
    } catch (_) {}
  }

  Future<void> deleteExpense(String id) async {
    await _db.deleteExpense(id);
    try {
      await _remote.delete(id);
    } catch (_) {}
  }

  Future<void> syncPending() async {
    final unsynced = await _db.getUnsyncedExpenses();
    for (final e in unsynced) {
      try {
        await _remote.insert(
          ExpenseModel(
            id: e.id,
            categoryId: e.categoryId,
            amount: e.amount,
            note: e.note,
            spentAt: e.spentAt,
          ),
        );
        await _db.markSynced(e.id);
      } catch (_) {
        continue;
      }
    }
  }

  Future<List<Expense>> fetchRange(DateTime start, DateTime end) =>
      _db.getExpensesInRange(start, end);

  Future<List<Expense>> fetchSameTimeWindow({
    required int hour,
    required int toleranceMinutes,
    required int lookbackDays,
  }) {
    return _db.getExpensesNearHour(
      hour: hour,
      toleranceMinutes: toleranceMinutes,
      lookbackDays: lookbackDays,
    );
  }
}
