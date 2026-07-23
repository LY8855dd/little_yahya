import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

String _categoryLabel(SpendCategory c) {
  switch (c) {
    case SpendCategory.urgentNeed:
      return 'Urgent need';
    case SpendCategory.monthlyNeed:
      return 'Monthly need';
    case SpendCategory.useful:
      return 'Useful';
    case SpendCategory.want:
      return 'Want';
    case SpendCategory.fastFood:
      return 'Fast food';
  }
}

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final savingsProgress =
        (state.thisMonthSavings / state.monthlySavingsGoalSar).clamp(0.0, 1.0);
    final sortedEntries = [...state.moneyEntries]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _addEntry(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('MONTHLY SAVINGS GOAL',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _editGoal(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${state.monthlySavingsGoalSar.toStringAsFixed(0)} SAR',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('${state.thisMonthSavings.toStringAsFixed(0)} SAR',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: savingsProgress,
                    backgroundColor: Colors.black.withValues(alpha: 0.25),
                    color: Colors.white,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.accent,
                    ),
                    onPressed: () => _addDeposit(context),
                    child: const Text('Add deposit'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.fastfood, color: AppTheme.warn),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fast food this month',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text(
                          'Compare with homemade costs in Food',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${state.thisMonthFastFoodSpend.toStringAsFixed(0)} SAR',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.warn),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'RECENT SPENDING'),
          if (sortedEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No spending logged yet.'),
            )
          else
            ...sortedEntries.map((e) => Card(
                  child: ListTile(
                    title: Text(e.label),
                    subtitle: Text(
                        '${_categoryLabel(e.category)} · ${DateFormat.MMMd().format(e.date)}'),
                    trailing: Text('${e.amountSar.toStringAsFixed(0)} SAR'),
                    onLongPress: () =>
                        context.read<AppState>().deleteMoneyEntry(e.id),
                  ),
                )),
        ],
      ),
    );
  }

  void _editGoal(BuildContext context, AppState state) {
    final controller =
        TextEditingController(text: state.monthlySavingsGoalSar.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly savings goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'SAR'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null) state.setSavingsGoal(v);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addDeposit(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add deposit'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount, SAR'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null) {
                context.read<AppState>().addSavingsDeposit(SavingsDeposit(amountSar: v));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addEntry(BuildContext context) {
    final label = TextEditingController();
    final amount = TextEditingController();
    SpendCategory category = SpendCategory.want;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Log spending'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: label, decoration: const InputDecoration(labelText: 'What')),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount, SAR'),
              ),
              const SizedBox(height: 8),
              DropdownButton<SpendCategory>(
                value: category,
                isExpanded: true,
                items: SpendCategory.values
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(_categoryLabel(c))))
                    .toList(),
                onChanged: (v) => setState(() => category = v ?? category),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(amount.text.trim());
                if (label.text.trim().isEmpty || v == null) return;
                context.read<AppState>().addMoneyEntry(MoneyEntry(
                      label: label.text.trim(),
                      amountSar: v,
                      category: category,
                    ));
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
