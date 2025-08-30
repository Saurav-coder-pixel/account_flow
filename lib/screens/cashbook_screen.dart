import 'package:flutter/material.dart';

enum EntryType {
  income,
  expense,
}

class CashbookEntry {
  final String id;
  final String description;
  final double amount;
  final EntryType type;
  final DateTime date;

  CashbookEntry({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });
}

class CashbookScreen extends StatefulWidget {
  @override
  _CashbookScreenState createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  final List<CashbookEntry> _entries = [];

  double get _totalIncome {
    return _entries
        .where((entry) => entry.type == EntryType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _totalExpense {
    return _entries
        .where((entry) => entry.type == EntryType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _balance {
    return _totalIncome - _totalExpense;
  }

  void _addEntry(String description, double amount, EntryType type) {
    final newEntry = CashbookEntry(
      id: DateTime.now().toString(),
      description: description,
      amount: amount,
      type: type,
      date: DateTime.now(),
    );
    setState(() {
      _entries.add(newEntry);
    });
  }

  void _deleteEntry(String id) {
    setState(() {
      _entries.removeWhere((entry) => entry.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Cashbook'),
      ),
      body: Column(
        children: [
          _buildSummary(),
          Expanded(child: _buildEntryList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Income',
              amount: _totalIncome,
              color: Colors.green,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'Expense',
              amount: _totalExpense,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      {required String title, required double amount, required MaterialColor color}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.shade700, color.shade400]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryList() {
    if (_entries.isEmpty) {
      return Center(
        child: Text('No entries yet. Tap + to add one!'),
      );
    }

    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              entry.type == EntryType.income
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: entry.type == EntryType.income ? Colors.green : Colors.red,
            ),
            title: Text(entry.description),
            subtitle: Text(entry.date.toString()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${entry.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: entry.type == EntryType.income
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => _deleteEntry(entry.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    EntryType type = EntryType.expense;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Entry'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Radio<EntryType>(
                          value: EntryType.expense,
                          groupValue: type,
                          onChanged: (EntryType? value) {
                            setState(() {
                              type = value!;
                            });
                          },
                        ),
                        Text('Expense'),
                        Radio<EntryType>(
                          value: EntryType.income,
                          groupValue: type,
                          onChanged: (EntryType? value) {
                            setState(() {
                              type = value!;
                            });
                          },
                        ),
                        Text('Income'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final description = descriptionController.text;
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (description.isNotEmpty && amount > 0) {
                  _addEntry(description, amount, type);
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
