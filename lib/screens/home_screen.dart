// lib/screens/home_screen.dart - FINAL VERSION WITH CLOUD SYNC
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense.dart';
import '../widgets/pie_chart_widget.dart';
import 'add_expense_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  late final CollectionReference expensesRef;
  String searchQuery = '';
  DateTime? selectedMonth;
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    expensesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses');
    _syncFromCloud();
  }

  Future<void> _syncFromCloud() async {
    final snapshot = await expensesRef.orderBy('date', descending: true).get();
    final box = Hive.box<Expense>('expenses');
    box.clear();
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      box.add(
        Expense(
          title: data['title'],
          amount: data['amount'].toDouble(),
          date: (data['date'] as Timestamp).toDate(),
          category: data['category'],
        )..id = doc.id,
      );
    }
  }

  Future<void> _saveToCloud(Expense e) async {
    await expensesRef.doc(e.id).set({
      'title': e.title,
      'amount': e.amount,
      'date': Timestamp.fromDate(e.date),
      'category': e.category,
    });
  }

  Future<void> _deleteFromCloud(String id) async {
    await expensesRef.doc(id).delete();
  }

  Future<void> _exportCsv() async {
    final expenses = Hive.box<Expense>('expenses').values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    String csv = 'Date,Title,Category,Amount\n';
    for (var e in expenses)
      csv +=
          '${DateFormat('yyyy-MM-dd').format(e.date)},${e.title},${e.category},${e.amount}\n';

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/expenses_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
    );
    await file.writeAsString(csv);
    Share.shareXFiles([XFile(file.path)], text: 'My Expenses');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hi, ${user.email!.split('@')[0]}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => isDark = !isDark),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
            },
          ),
          IconButton(icon: const Icon(Icons.download), onPressed: _exportCsv),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Expense>('expenses').listenable(),
        builder: (context, Box<Expense> box, _) {
          var expenses = box.values.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          // Apply filters
          if (selectedMonth != null) {
            expenses = expenses
                .where(
                  (e) =>
                      e.date.year == selectedMonth!.year &&
                      e.date.month == selectedMonth!.month,
                )
                .toList();
          }
          if (searchQuery.isNotEmpty) {
            expenses = expenses
                .where(
                  (e) =>
                      e.title.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ||
                      e.category.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ),
                )
                .toList();
          }

          final total = expenses.fold<double>(0, (s, e) => s + e.amount);

          return Column(
            children: [
              // Filters Row
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<DateTime?>(
                        value: selectedMonth,
                        decoration: InputDecoration(
                          labelText: 'Month',
                          prefixIcon: const Icon(Icons.calendar_month),
                          filled: true,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Time'),
                          ),
                          ...expenses
                              .map((e) => DateTime(e.date.year, e.date.month))
                              .toSet()
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    DateFormat('MMMM yyyy').format(d),
                                  ),
                                ),
                              ),
                        ],
                        onChanged: (v) => setState(() => selectedMonth = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => searchQuery = ''),
                                )
                              : null,
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Total Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        selectedMonth == null
                            ? 'All Time'
                            : DateFormat('MMMM yyyy').format(selectedMonth!),
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('${expenses.length} expenses'),
                    ],
                  ),
                ),
              ),

              expenses.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text(
                          'No expenses yet! Add one',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (_, i) {
                          final e = expenses[i];
                          return Dismissible(
                            key: Key(e.id),
                            onDismissed: (_) {
                              box.delete(e.key);
                              _deleteFromCloud(e.id);
                            },
                            child: ListTile(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddExpenseScreen(expenseToEdit: e),
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: categoryColors[e.category],
                                child: Icon(
                                  _getIcon(e.category),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(e.title),
                              subtitle: Text(
                                '${e.category} • ${DateFormat('dd MMM yyyy').format(e.date)}',
                              ),
                              trailing: Text(
                                '₹${e.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          if (result == true) _syncFromCloud(); // refresh after add/edit
        },
        label: const Text('Add Expense'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIcon(String c) => switch (c) {
    'Food' => Icons.restaurant,
    'Transport' => Icons.directions_car,
    'Shopping' => Icons.shopping_bag,
    'Entertainment' => Icons.movie,
    'Bills' => Icons.receipt_long,
    'Health' => Icons.local_hospital,
    _ => Icons.category,
  };
}
