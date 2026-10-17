class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
  });

  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String note;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
    );
  }
}

class ExpenseData {
  const ExpenseData({
    required this.expenses,
    required this.categories,
    required this.monthlyBudget,
  });

  final List<Expense> expenses;
  final List<String> categories;
  final double monthlyBudget;

  Map<String, Object?> toJson() => {
    'expenses': expenses.map((expense) => expense.toJson()).toList(),
    'categories': categories,
    'monthlyBudget': monthlyBudget,
  };

  factory ExpenseData.fromJson(Map<String, dynamic> json) {
    return ExpenseData(
      expenses: (json['expenses'] as List<dynamic>)
          .map((item) => Expense.fromJson(item as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      monthlyBudget: (json['monthlyBudget'] as num).toDouble(),
    );
  }
}
