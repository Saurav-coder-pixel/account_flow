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
  const CashbookScreen({super.key});

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
    final List<Color> gradientColors = _balance >= 0
        ? [Colors.green.shade700, Colors.green.shade400]
        : [Colors.red.shade700, Colors.red.shade400];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildSummary(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _buildEntryList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(gradientColors),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Text(
              'Personal Cashbook',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(child: _buildSummaryCard('Income', _totalIncome, Icons.arrow_upward)),
          const SizedBox(width: 16),
          Expanded(child: _buildSummaryCard('Expense', _totalExpense, Icons.arrow_downward)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList() {
    if (_entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No entries yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add your first transaction',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _entries.length + 1, // +1 for the total balance footer
      itemBuilder: (context, index) {
        if (index == _entries.length) {
          return _buildTotalBalanceFooter();
        }
        final entry = _entries[index];
        final isIncome = entry.type == EntryType.income;
        return ListTile(
          leading: Icon(
            isIncome ? Icons.arrow_circle_up_outlined : Icons.arrow_circle_down_outlined,
            color: isIncome ? Colors.green : Colors.red,
            size: 40,
          ),
          title: Text(entry.description, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(DateFormat('MMM dd, yyyy • hh:mm a').format(entry.date)),
          trailing: Text(
            '${isIncome ? '+' : '-'} ₹${entry.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isIncome ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalBalanceFooter() {
    final List<Color> gradientColors = _balance >= 0
        ? [Colors.green.shade700, Colors.green.shade400]
        : [Colors.red.shade700, Colors.red.shade400];

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 80), // Adjust bottom margin to avoid FAB overlap
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Total Balance',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            '₹${_balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  Widget _buildFloatingActionButton(List<Color> gradientColors) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddEntryDialog(context),
      label: const Text('Add Transaction'),
      icon: const Icon(Icons.add),
      backgroundColor: Colors.white,
      foregroundColor: gradientColors[0],
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    EntryType selectedType = EntryType.income;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Entry'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount.';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number.';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Please enter an amount greater than zero.';
                        }
                        return null;
                      },
                    ),
                    Row(
                      children: [
                        Radio<EntryType>(
                          value: EntryType.income,
                          groupValue: selectedType,
                          onChanged: (type) {
                            setState(() {
                              selectedType = type!;
                            });
                          },
                        ),
                        const Text('Income'),
                        Radio<EntryType>(
                          value: EntryType.expense,
                          groupValue: selectedType,
                          onChanged: (type) {
                            setState(() {
                              selectedType = type!;
                            });
                          },
                        ),
                        const Text('Expense'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final description = descriptionController.text;
                      final amount = double.parse(amountController.text);
                      _addEntry(description, amount, selectedType);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
