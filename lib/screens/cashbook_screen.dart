import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
          _buildTotalBalanceCard(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Income', _totalIncome, Colors.green),
            _buildSummaryItem('Expense', _totalExpense, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard() {
    return Card(
      margin: EdgeInsets.fromLTRB(16, 100, 16, 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 100),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Balance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '₹${_balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildEntryList() {
    return _entries.isEmpty
        ? Center(
      child: Text('No entries yet.'),
    )
        : ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final isIncome = entry.type == EntryType.income;
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
              isIncome ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            title: Text(entry.description),
            subtitle: Text(DateFormat.yMMMd().format(entry.date)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isIncome ? '+' : '-'} ₹${entry.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
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
    final _descriptionController = TextEditingController();
    final _amountController = TextEditingController();
    EntryType _selectedType = EntryType.income;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Entry'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  Row(
                    children: [
                      Radio<EntryType>(
                        value: EntryType.income,
                        groupValue: _selectedType,
                        onChanged: (type) {
                          setState(() {
                            _selectedType = type!;
                          });
                        },
                      ),
                      Text('Income'),
                      Radio<EntryType>(
                        value: EntryType.expense,
                        groupValue: _selectedType,
                        onChanged: (type) {
                          setState(() {
                            _selectedType = type!;
                          });
                        },
                      ),
                      Text('Expense'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final description = _descriptionController.text;
                    final amount = double.tryParse(_amountController.text) ?? 0.0;
                    if (description.isNotEmpty && amount > 0) {
                      _addEntry(description, amount, _selectedType);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
