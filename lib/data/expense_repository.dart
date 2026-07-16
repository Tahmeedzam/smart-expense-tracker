import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

// ── Models ───────────────────────────────────────────────────────────

class ExpenseModel {
  final String id;
  final String categoryId;
  final double amount;
  final String? note;
  final DateTime spentAt;

  ExpenseModel({
    required this.id,
    required this.categoryId,
    required this.amount,
    this.note,
    required this.spentAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
    id: map['id'] as String,
    categoryId: map['category_id'] as String,
    amount: (map['amount'] as num).toDouble(),
    note: map['note'] as String?,
    spentAt: DateTime.parse(map['spent_at'] as String),
  );

  Map<String, dynamic> toMap(String userId) => {
    'id': id,
    'user_id': userId,
    'category_id': categoryId,
    'amount': amount,
    'note': note,
    'spent_at': spentAt.toIso8601String(),
  };
}

class ExpenseRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<void> insert(ExpenseModel expense) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('expenses').upsert(expense.toMap(userId));
    // upsert (not insert) — makes retried syncs idempotent since id
    // is client-generated and stable across retries.
  }

  Future<void> delete(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }
}
