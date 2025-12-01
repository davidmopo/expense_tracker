// Add these imports at the top
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';

// Inside _HomeScreenState class, add this at the top:
final user = FirebaseAuth.instance.currentUser!;
late final CollectionReference _expensesRef;

// In initState():
@override
void initState() {
  super.initState();
  _expensesRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('expenses');
  _loadExpensesFromCloud();
}

Future<void> _loadExpensesFromCloud() async {
  final snapshot = await _expensesRef.orderBy('date', descending: true).get();
  final box = Hive.box<Expense>('expenses');
  await box.clear();

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final expense = Expense(
      title: data['title'],
      amount: data['amount'].toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'],
    );
    expense.id = doc.id;
    await box.add(expense);
  }
  setState(() {});
}

// Call this after adding/editing/deleting:
Future<void> _syncExpenseToCloud(Expense expense) async {
  await _expensesRef.doc(expense.id).set({
    'title': expense.title,
    'amount': expense.amount,
    'date': Timestamp.fromDate(expense.date),
    'category': expense.category,
  });
}

// In ListTile onDismissed and AddExpenseScreen save → call _syncExpenseToCloud(e)

// Add logout button in AppBar actions:
IconButton(
  icon: const Icon(Icons.logout),
  onPressed: () async {
    await FirebaseAuth.instance.signOut();
  },
)