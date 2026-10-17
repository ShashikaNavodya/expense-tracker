import 'package:flutter/material.dart';

import '../models/expense.dart';

const categoryColors = <String, Color>{
  'Food & Drink': Color(0xFFFF9F68),
  'Transport': Color(0xFF5B8DEF),
  'Shopping': Color(0xFFB17BE4),
  'Bills': Color(0xFF45B7A0),
  'Health': Color(0xFFE77487),
  'Entertainment': Color(0xFFEEBF4E),
  'Other': Color(0xFF82908D),
};

const categoryIcons = <String, IconData>{
  'Food & Drink': Icons.restaurant_rounded,
  'Transport': Icons.directions_car_filled_rounded,
  'Shopping': Icons.shopping_bag_rounded,
  'Bills': Icons.receipt_long_rounded,
  'Health': Icons.favorite_rounded,
  'Entertainment': Icons.movie_rounded,
  'Other': Icons.grid_view_rounded,
};

Color categoryColor(String category) =>
    categoryColors[category] ?? const Color(0xFF82908D);

IconData categoryIcon(String category) =>
    categoryIcons[category] ?? Icons.grid_view_rounded;

String formatMoney(num amount, {bool decimals = false}) {
  final rounded = amount.toStringAsFixed(decimals ? 2 : 0);
  final parts = rounded.split('.');
  final integer = parts.first;
  final grouped = integer.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '\$$grouped${decimals ? '.${parts.last}' : ''}';
}

String formatDate(DateTime date) {
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
  return '${date.day} ${months[date.month - 1]}';
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(22),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17271F),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(expense.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(categoryIcon(expense.category), color: color, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF202B25),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expense.category}  ·  ${formatDate(expense.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF899590),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '−${formatMoney(expense.amount)}',
            style: const TextStyle(
              color: Color(0xFF26332F),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Expense actions',
            onSelected: (action) => action == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit expense')),
              PopupMenuItem(value: 'delete', child: Text('Delete expense')),
            ],
          ),
        ],
      ),
    );
  }
}
