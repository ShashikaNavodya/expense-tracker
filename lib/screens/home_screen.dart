import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_storage.dart';
import '../widgets/expense_form_dialog.dart';
import '../widgets/expense_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExpenseStorage _storage = ExpenseStorage();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  ExpenseData? _data;
  Object? _loadError;
  bool _loading = true;
  int _selectedPage = 0;
  String _selectedCategory = 'All categories';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_updateSearch);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_updateSearch)
      ..dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final data = await _storage.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _budgetController.text = data.monthlyBudget.toStringAsFixed(0);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  void _updateSearch() {
    if (_searchQuery == _searchController.text) return;
    setState(() => _searchQuery = _searchController.text);
  }

  Future<bool> _commitData(ExpenseData updated) async {
    try {
      await _storage.save(updated);
      if (!mounted) return false;
      setState(() => _data = updated);
      return true;
    } catch (error) {
      if (mounted) _showMessage('Could not save your changes: $error');
      return false;
    }
  }

  Future<void> _addExpense({Expense? expense}) async {
    final data = _data;
    if (data == null) return;
    final result = await showDialog<Expense>(
      context: context,
      builder: (context) =>
          ExpenseFormDialog(categories: data.categories, expense: expense),
    );
    if (result == null || !mounted) return;
    final expenses = [...data.expenses];
    final index = expenses.indexWhere((item) => item.id == result.id);
    if (index == -1) {
      expenses.insert(0, result);
    } else {
      expenses[index] = result;
    }
    final saved = await _commitData(
      ExpenseData(
        expenses: expenses,
        categories: data.categories,
        monthlyBudget: data.monthlyBudget,
      ),
    );
    if (saved && mounted) {
      _showMessage(expense == null ? 'Expense added' : 'Expense updated');
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: Text('"${expense.title}" will be removed from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD9534F),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    final data = _data;
    if (confirmed != true || data == null) return;
    final saved = await _commitData(
      ExpenseData(
        expenses: data.expenses.where((item) => item.id != expense.id).toList(),
        categories: data.categories,
        monthlyBudget: data.monthlyBudget,
      ),
    );
    if (saved && mounted) _showMessage('Expense deleted');
  }

  Future<void> _saveBudget() async {
    final data = _data;
    final budget = double.tryParse(_budgetController.text.trim());
    if (data == null || budget == null || !budget.isFinite || budget <= 0) {
      _showMessage('Enter a monthly budget greater than zero.');
      return;
    }
    final saved = await _commitData(
      ExpenseData(
        expenses: data.expenses,
        categories: data.categories,
        monthlyBudget: budget,
      ),
    );
    if (saved && mounted) _showMessage('Monthly budget updated');
  }

  Future<void> _manageCategories() async {
    final data = _data;
    if (data == null) return;
    final controller = TextEditingController();
    final updatedCategories = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        var categories = [...data.categories];
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void addCategory() {
              final name = controller.text.trim();
              if (name.isEmpty) {
                setDialogState(() => errorText = 'Enter a category name');
              } else if (categories.any(
                (item) => item.toLowerCase() == name.toLowerCase(),
              )) {
                setDialogState(
                  () => errorText = 'That category already exists',
                );
              } else {
                setDialogState(() {
                  categories.add(name);
                  errorText = null;
                  controller.clear();
                });
              }
            }

            return AlertDialog(
              title: const Text('Manage categories'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'New category name',
                              errorText: errorText,
                            ),
                            onSubmitted: (_) => addCategory(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: addCategory,
                          tooltip: 'Add category',
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: categories.map((category) {
                          final hasExpenses = data.expenses.any(
                            (expense) => expense.category == category,
                          );
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 17,
                              backgroundColor: categoryColor(
                                category,
                              ).withValues(alpha: 0.12),
                              child: Icon(
                                categoryIcon(category),
                                size: 17,
                                color: categoryColor(category),
                              ),
                            ),
                            title: Text(category),
                            subtitle: hasExpenses
                                ? const Text('Used by existing expenses')
                                : null,
                            trailing: IconButton(
                              tooltip: hasExpenses
                                  ? 'Move or delete expenses before removing'
                                  : 'Remove category',
                              onPressed: hasExpenses
                                  ? null
                                  : () => setDialogState(
                                      () => categories.remove(category),
                                    ),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: categories.isEmpty
                      ? null
                      : () => Navigator.pop(dialogContext, categories),
                  child: const Text('Save categories'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    if (updatedCategories == null || !mounted) return;
    final saved = await _commitData(
      ExpenseData(
        expenses: data.expenses,
        categories: updatedCategories,
        monthlyBudget: data.monthlyBudget,
      ),
    );
    if (saved && mounted && !updatedCategories.contains(_selectedCategory)) {
      setState(() => _selectedCategory = 'All categories');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) =>
                  _buildHeader(compact: constraints.maxWidth < 1120),
            ),
            const Divider(height: 1, color: Color(0xFFE8EDEA)),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF16865F),
                      ),
                    )
                  : _loadError != null
                  ? _buildLoadError()
                  : LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 44),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1220),
                            child: _buildPage(
                              (constraints.maxWidth - 44).clamp(0.0, 1220.0),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({required bool compact}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1264),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 22,
            vertical: 13,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F5F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF0F9D78),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MINTLY',
                        style: TextStyle(
                          fontSize: 15,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF18252B),
                        ),
                      ),
                      Text(
                        'MONEY, MADE EASY',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 1.3,
                          color: Color(0xFF8B9893),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 52),
                    _navigationItems(),
                  ],
                  const Spacer(),
                  IconButton(
                    tooltip: 'Manage categories',
                    onPressed: _data == null ? null : _manageCategories,
                    icon: const Icon(Icons.tune_rounded),
                  ),
                  const SizedBox(width: 5),
                  FilledButton.icon(
                    onPressed: _data == null ? null : () => _addExpense(),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: Text(compact ? 'Add' : 'Add expense'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 17,
                        vertical: 13,
                      ),
                    ),
                  ),
                ],
              ),
              if (compact) ...[
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _navigationItems(compact: true),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _navigationItems({bool compact = false}) {
    const labels = ['Overview', 'Transactions', 'Budget'];
    const icons = [
      Icons.grid_view_rounded,
      Icons.receipt_long_rounded,
      Icons.track_changes_rounded,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(labels.length, (index) {
        final selected = index == _selectedPage;
        return Padding(
          padding: EdgeInsets.only(right: compact ? 5 : 7),
          child: TextButton.icon(
            onPressed: () => setState(() => _selectedPage = index),
            icon: Icon(icons[index], size: 17),
            label: Text(labels[index]),
            style: TextButton.styleFrom(
              foregroundColor: selected
                  ? const Color(0xFF0F8D6D)
                  : const Color(0xFF78847F),
              backgroundColor: selected
                  ? const Color(0xFFE8F5F0)
                  : Colors.transparent,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 13,
                vertical: 11,
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFD97862),
              size: 38,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your expense data could not be loaded.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              '$_loadError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF78847F), fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(double width) {
    final data = _data!;
    return switch (_selectedPage) {
      1 => _buildTransactions(data, width),
      2 => _buildBudget(data, width),
      _ => _buildOverview(data, width),
    };
  }

  Widget _buildPageHeading({
    required String eyebrow,
    required String title,
    required String description,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF0F9D78),
                    letterSpacing: 1.4,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 7),
                Text(description),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildOverview(ExpenseData data, double width) {
    final thisMonth = _currentMonthExpenses(data.expenses);
    final total = thisMonth.fold<double>(0, (sum, item) => sum + item.amount);
    final budgetProgress =
        (data.monthlyBudget == 0 ? 0 : total / data.monthlyBudget)
            .clamp(0.0, 1.0)
            .toDouble();
    final recent = [...data.expenses]..sort((a, b) => b.date.compareTo(a.date));
    final chartAndCategories = width > 840
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _buildSpendingChart(data)),
              const SizedBox(width: 18),
              Expanded(flex: 4, child: _buildCategoryBreakdown(thisMonth)),
            ],
          )
        : Column(
            children: [
              _buildSpendingChart(data),
              const SizedBox(height: 18),
              _buildCategoryBreakdown(thisMonth),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeading(
          eyebrow: _monthLabel(DateTime.now()),
          title: 'Make room for what matters.',
          description: 'A clearer view of your money starts right here.',
          trailing: width > 560 ? _monthDateBadge() : null,
        ),
        _buildSpendingHero(
          total,
          thisMonth.length,
          data,
          budgetProgress,
          width,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _buildStatCard(
              width: _statWidth(width),
              title: 'Budget remaining',
              value: formatMoney(data.monthlyBudget - total),
              detail:
                  '${(budgetProgress * 100).round()}% of ${formatMoney(data.monthlyBudget)} used',
              icon: Icons.savings_outlined,
              color: const Color(0xFF5B8DEF),
              progress: budgetProgress,
            ),
            _buildStatCard(
              width: _statWidth(width),
              title: 'Average per day',
              value: formatMoney(total / DateTime.now().day),
              detail: 'Based on this month so far',
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFFEEA94D),
              trend: 'Daily average',
            ),
          ],
        ),
        const SizedBox(height: 18),
        chartAndCategories,
        const SizedBox(height: 18),
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(22, 18, 14, 8),
          child: Column(
            children: [
              _sectionHeading(
                'Recent transactions',
                'Your latest spending at a glance',
                actionLabel: 'View all',
                onAction: () => setState(() => _selectedPage = 1),
              ),
              if (recent.isEmpty)
                const _EmptyState(
                  title: 'No expenses yet',
                  description: 'Add your first expense to get started.',
                )
              else
                ...recent
                    .take(5)
                    .map(
                      (expense) => ExpenseListTile(
                        expense: expense,
                        onEdit: () => _addExpense(expense: expense),
                        onDelete: () => _deleteExpense(expense),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Your data stays on this device.',
            style: TextStyle(color: Color(0xFF9AA49F), fontSize: 11),
          ),
        ),
      ],
    );
  }

  double _statWidth(double availableWidth) {
    if (availableWidth < 570) return availableWidth;
    return (availableWidth - 14) / 2;
  }

  Widget _buildSpendingHero(
    double total,
    int transactionCount,
    ExpenseData data,
    double progress,
    double width,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF172F28), Color(0xFF245C47)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: width < 640
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heroAmount(total, transactionCount),
                      const SizedBox(height: 24),
                      _heroBudget(data, progress),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _heroAmount(total, transactionCount)),
                      const SizedBox(width: 34),
                      Expanded(child: _heroBudget(data, progress)),
                    ],
                  ),
          ),
          Positioned(
            top: -85,
            right: width < 640 ? -120 : 165,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x24FFFFFF)),
                ),
              ),
            ),
          ),
          Positioned(
            top: -48,
            right: width < 640 ? -82 : 203,
            child: IgnorePointer(
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x18FFFFFF)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroAmount(double total, int transactionCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'TOTAL SPENT',
              style: TextStyle(
                color: Color(0xFFC1D8CC),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFB9F0D5).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFB9F0D5),
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'THIS MONTH',
                    style: TextStyle(
                      color: Color(0xFFB9F0D5),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatMoney(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              height: 1.05,
              letterSpacing: -1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          '$transactionCount ${transactionCount == 1 ? 'transaction' : 'transactions'} so far',
          style: const TextStyle(color: Color(0xFFC1D8CC), fontSize: 12),
        ),
      ],
    );
  }

  Widget _heroBudget(ExpenseData data, double progress) {
    final spent = _currentMonthExpenses(
      data.expenses,
    ).fold<double>(0, (sum, expense) => sum + expense.amount);
    final remaining = data.monthlyBudget - spent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MONTHLY BUDGET',
          style: TextStyle(
            color: Color(0xFFC1D8CC),
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                formatMoney(data.monthlyBudget),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: Color(0xFFB9F0D5),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        _ProgressBar(
          value: progress,
          color: const Color(0xFF9BE6BD),
          background: const Color(0xFF416957),
          height: 8,
        ),
        const SizedBox(height: 11),
        Text(
          remaining >= 0
              ? '${formatMoney(remaining)} left to spend'
              : '${formatMoney(remaining.abs())} over budget',
          style: TextStyle(
            color: remaining >= 0
                ? const Color(0xFFC1D8CC)
                : const Color(0xFFFFC4B5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required double width,
    required String title,
    required String value,
    required String detail,
    required IconData icon,
    required Color color,
    String? trend,
    double? progress,
  }) {
    return SizedBox(
      width: width,
      child: SurfaceCard(
        padding: const EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                if (trend != null)
                  Text(
                    trend,
                    style: const TextStyle(
                      color: Color(0xFF929C97),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (progress != null)
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 17),
            Text(title, style: const TextStyle(color: Color(0xFF77837E))),
            const SizedBox(height: 5),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1D2D28),
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF9AA49F), fontSize: 11),
            ),
            if (progress != null) ...[
              const SizedBox(height: 11),
              _ProgressBar(value: progress, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _monthDateBadge() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            color: Color(0xFF0F9D78),
            size: 15,
          ),
          const SizedBox(width: 8),
          Text(
            '${_monthLabel(now)} ${now.year}',
            style: const TextStyle(
              color: Color(0xFF4C5B55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(ExpenseData data) {
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      final date = DateTime(now.year, now.month - 5 + index);
      final amount = data.expenses
          .where((expense) => _sameMonth(expense.date, date))
          .fold<double>(0, (sum, expense) => sum + expense.amount);
      return (date: date, amount: amount);
    });
    final maxAmount = months.fold<double>(
      0,
      (maximum, item) => item.amount > maximum ? item.amount : maximum,
    );
    final graphMax = maxAmount == 0 ? 1.0 : maxAmount;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Spending overview', 'Your last six months'),
          const SizedBox(height: 19),
          SizedBox(
            height: 174,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((month) {
                final isCurrent = _sameMonth(month.date, now);
                final barHeight = month.amount == 0
                    ? 5.0
                    : 14 + 112 * month.amount / graphMax;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (month.amount > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatMoney(month.amount),
                              style: const TextStyle(
                                color: Color(0xFF8A9691),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF0F9D78)
                                : const Color(0xFFDCEFE8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          _shortMonth(month.date),
                          style: TextStyle(
                            color: isCurrent
                                ? const Color(0xFF0F9D78)
                                : const Color(0xFF99A39E),
                            fontSize: 10,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<Expense> expenses) {
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<double>(0, (sum, item) => sum + item.value);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'By category',
            'This month’s breakdown',
            actionLabel: 'Manage',
            onAction: _manageCategories,
          ),
          if (sorted.isEmpty)
            const _EmptyState(
              title: 'Nothing to break down',
              description: 'Add an expense to see your categories here.',
            )
          else
            ...sorted.take(5).map((item) {
              final color = categoryColor(item.key);
              final proportion = total == 0 ? 0.0 : item.value / total;
              return Padding(
                padding: const EdgeInsets.only(top: 17),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(categoryIcon(item.key), size: 16, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.key,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF65736D),
                            ),
                          ),
                        ),
                        Text(
                          formatMoney(item.value),
                          style: const TextStyle(
                            color: Color(0xFF26332F),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ProgressBar(value: proportion, color: color, height: 5),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTransactions(ExpenseData data, double width) {
    final filtered = [...data.expenses]
      ..sort((a, b) => b.date.compareTo(a.date));
    final visible = filtered.where((expense) {
      final matchesCategory =
          _selectedCategory == 'All categories' ||
          expense.category == _selectedCategory;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          expense.title.toLowerCase().contains(query) ||
          expense.category.toLowerCase().contains(query) ||
          expense.note.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
    final total = visible.fold<double>(0, (sum, item) => sum + item.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeading(
          eyebrow: 'Expense history',
          title: 'Every little detail.',
          description: '${data.expenses.length} expenses saved on this device.',
          trailing: width > 560 ? _monthDateBadge() : null,
        ),
        SurfaceCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: width > 700 ? 360 : width,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search expenses or notes',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: _searchController.clear,
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width > 700 ? 210 : width,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.filter_list_rounded),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'All categories',
                          child: Text('All categories'),
                        ),
                        ...data.categories.map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF26332F),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${visible.length} shown  ·  ${formatMoney(total)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF86928C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFE9EEEC)),
              if (visible.isEmpty)
                _EmptyState(
                  title: data.expenses.isEmpty
                      ? 'No expenses to show'
                      : 'No matching expenses',
                  description: data.expenses.isEmpty
                      ? 'Add an expense to begin your history.'
                      : 'Try another search or category filter.',
                  action: data.expenses.isEmpty
                      ? FilledButton.icon(
                          onPressed: () => _addExpense(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add expense'),
                        )
                      : null,
                )
              else
                ...visible.map(
                  (expense) => ExpenseListTile(
                    expense: expense,
                    onEdit: () => _addExpense(expense: expense),
                    onDelete: () => _deleteExpense(expense),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudget(ExpenseData data, double width) {
    final expenses = _currentMonthExpenses(data.expenses);
    final spent = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    final remaining = data.monthlyBudget - spent;
    final progress = (spent / data.monthlyBudget).clamp(0.0, 1.0).toDouble();
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final categories = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeading(
          eyebrow: _monthLabel(DateTime.now()),
          title: 'A plan that feels good.',
          description: 'Set your monthly limit and keep spending in view.',
        ),
        SurfaceCard(
          color: const Color(0xFF163B32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MONTHLY SPENDING LIMIT',
                style: TextStyle(
                  color: Color(0xFFAED6C7),
                  letterSpacing: 1.3,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                formatMoney(data.monthlyBudget),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 35,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 18),
              _ProgressBar(
                value: progress,
                color: const Color(0xFF62D4A9),
                background: const Color(0xFF2D544A),
                height: 9,
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Text(
                    '${formatMoney(spent)} spent',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    remaining >= 0
                        ? '${formatMoney(remaining)} left'
                        : '${formatMoney(remaining.abs())} over budget',
                    style: TextStyle(
                      color: remaining < 0
                          ? const Color(0xFFFFB5A8)
                          : const Color(0xFFAED6C7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading(
                'Update your budget',
                'Your budget resets automatically each month.',
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monthly budget',
                        prefixText: '\$ ',
                      ),
                      onSubmitted: (_) => _saveBudget(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _saveBudget,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Save budget'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading(
                'This month by category',
                'See what’s using your budget',
                actionLabel: 'Manage',
                onAction: _manageCategories,
              ),
              if (categories.isEmpty)
                const _EmptyState(
                  title: 'No spending recorded',
                  description: 'Your category breakdown will appear here.',
                )
              else
                ...categories.map((entry) {
                  final fraction = data.monthlyBudget == 0
                      ? 0.0
                      : (entry.value / data.monthlyBudget).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Row(
                      children: [
                        Icon(
                          categoryIcon(entry.key),
                          color: categoryColor(entry.key),
                          size: 18,
                        ),
                        const SizedBox(width: 11),
                        SizedBox(
                          width: 132,
                          child: Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: _ProgressBar(
                            value: fraction.toDouble(),
                            color: categoryColor(entry.key),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          formatMoney(entry.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeading(
    String title,
    String subtitle, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: Color(0xFF0F9D78),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  List<Expense> _currentMonthExpenses(List<Expense> expenses) => expenses
      .where((expense) => _sameMonth(expense.date, DateTime.now()))
      .toList();

  bool _sameMonth(DateTime left, DateTime right) =>
      left.year == right.year && left.month == right.month;

  String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[date.month - 1];
  }

  String _shortMonth(DateTime date) {
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
    return months[date.month - 1];
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.color,
    this.background = const Color(0xFFEDF1EF),
    this.height = 6,
  });

  final double value;
  final Color color;
  final Color background;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: background,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
    this.action,
  });

  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 12),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFFAAB5AF),
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF4A5A53),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A09A), fontSize: 11),
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
