import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'default_categories.dart';

part 'local_database.g.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get spentAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Categories, Expenses])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await batch((b) {
        b.insertAll(
          categories,
          defaultCategories,
          mode: InsertMode.insertOrIgnore,
        );
      });
    },
  );

  Future<List<Category>> getAllCategories() => select(categories).get();

  Future<void> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry, mode: InsertMode.insertOrReplace);

  Future<void> insertExpense(ExpensesCompanion entry) =>
      into(expenses).insert(entry, mode: InsertMode.insertOrReplace);

  Future<List<Expense>> getExpensesInRange(DateTime start, DateTime end) {
    return (select(expenses)
          ..where((e) => e.spentAt.isBetweenValues(start, end))
          ..orderBy([(e) => OrderingTerm.desc(e.spentAt)]))
        .get();
  }

  Future<void> deleteExpense(String id) =>
      (delete(expenses)..where((e) => e.id.equals(id))).go();

  Future<List<Expense>> getExpensesNearHour({
    required int hour,
    required int toleranceMinutes,
    required int lookbackDays,
  }) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final since = todayStart.subtract(Duration(days: lookbackDays));

    final rows = await (select(
      expenses,
    )..where((e) => e.spentAt.isBiggerOrEqualValue(since))).get();

    return rows.where((e) {
      // Exclude anything from today — only match PAST days' patterns.
      if (!e.spentAt.isBefore(todayStart)) return false;

      final minutesFromHour =
          (e.spentAt.hour * 60 + e.spentAt.minute) - (hour * 60);
      return minutesFromHour.abs() <= toleranceMinutes;
    }).toList();
  }

  Future<List<Expense>> getUnsyncedExpenses() =>
      (select(expenses)..where((e) => e.synced.equals(false))).get();

  Future<void> markSynced(String expenseId) =>
      (update(expenses)..where((e) => e.id.equals(expenseId))).write(
        const ExpensesCompanion(synced: Value(true)),
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'expense_tracker.sqlite'));

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
