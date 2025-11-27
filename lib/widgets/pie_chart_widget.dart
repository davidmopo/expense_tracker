import 'package:flutter/material.dart';
import '../models/expense.dart';

class PieChartWidget extends StatelessWidget {
  final List<Expense> expenses;

  const PieChartWidget({Key? key, required this.expenses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group expenses by category
    final Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    // Calculate total
    double totalAmount = expenses.fold(0, (sum, e) => sum + e.amount);

    // Category colors
    final Map<String, Color> categoryColors = {
      'Food': Colors.orange,
      'Transport': Colors.blue,
      'Shopping': Colors.purple,
      'Entertainment': Colors.pink,
      'Bills': Colors.red,
      'Health': Colors.green,
      'Education': Colors.teal,
      'Other': Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Expenses by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: categoryTotals.length,
              itemBuilder: (context, index) {
                final entry = categoryTotals.entries.elementAt(index);
                final percentage = (entry.value / totalAmount * 100);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: categoryColors[entry.key] ?? Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entry.key),
                      ),
                      Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
