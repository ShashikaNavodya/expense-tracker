import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

class ExpenseStorage {
  static const _storageKey = 'auspify_expense_tracker_v1';

  Future<ExpenseData> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedData = preferences.getString(_storageKey);
    if (savedData != null) {
      return ExpenseData.fromJson(
        jsonDecode(savedData) as Map<String, dynamic>,
      );
    }

    final initialData = _starterData();
    await save(initialData);
    return initialData;
  }

  Future<void> save(ExpenseData data) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(data.toJson()),
    );
    if (!saved) {
      throw StateError('The expense data could not be saved on this device.');
    }
  }

  ExpenseData _starterData() {
    final today = DateTime.now();
    return ExpenseData(
      monthlyBudget: 50000,
      categories: const [
        'Food & Drink',
        'Transport',
        'Shopping',
        'Bills',
        'Health',
        'Entertainment',
        'Other',
      ],
      expenses: [
        Expense(
          id: 'sample-coffee',
          title: 'Coffee & breakfast',
          category: 'Food & Drink',
          amount: 420,
          date: DateTime(today.year, today.month, today.day),
          note: 'Starter example',
        ),
        Expense(
          id: 'sample-market',
          title: 'Weekly groceries',
          category: 'Food & Drink',
          amount: 1840,
          date: DateTime(today.year, today.month, today.day - 1),
          note: 'Starter example',
        ),
        Expense(
          id: 'sample-ride',
          title: 'Ride to work',
          category: 'Transport',
          amount: 265,
          date: DateTime(today.year, today.month, today.day - 2),
          note: 'Starter example',
        ),
        Expense(
          id: 'sample-bills',
          title: 'Internet bill',
          category: 'Bills',
          amount: 999,
          date: DateTime(today.year, today.month, today.day - 3),
          note: 'Starter example',
        ),
        Expense(
          id: 'sample-book',
          title: 'A good read',
          category: 'Shopping',
          amount: 650,
          date: DateTime(today.year, today.month, today.day - 5),
          note: 'Starter example',
        ),
      ],
    );
  }
}
