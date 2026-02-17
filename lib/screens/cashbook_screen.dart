import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../models/transaction.dart' as app_transaction;
import '../providers/person_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/app_drawer.dart';

class CashbookScreen extends StatelessWidget {
  const CashbookScreen({super.key});

  Future<Person> _findOrCreateCashbookPerson(PersonProvider personProvider) async {
    const cashbookPersonName = 'Personal Cashbook';
    final cashbookPersons = await personProvider.getCashbookPersons();
    Person? person = cashbookPersons.isNotEmpty ? cashbookPersons.first : null;
    person ??= await personProvider.addPerson(Person(name: cashbookPersonName, createdAt: DateTime.now(), isCashbook: true));
    return person;
  }

  @override
  Widget build(BuildContext context) {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);

    return FutureBuilder<Person>(
      future: _findOrCreateCashbookPerson(personProvider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Personal Cashbook')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final cashbookPerson = snapshot.data!;

        return Consumer<TransactionProvider>(
          builder: (context, transactionProvider, child) {
            final entries = transactionProvider.getTransactionsForPerson(cashbookPerson.id!);

            final totalIncome = entries
                .where((e) => e.type == app_transaction.TransactionType.credit)
                .fold(0.0, (sum, item) => sum + item.amount);

            final totalExpense = entries
                .where((e) => e.type == app_transaction.TransactionType.debit)
                .fold(0.0, (sum, item) => sum + item.amount);

            final balance = totalIncome - totalExpense;

            final List<Color> gradientColors = balance >= 0
                ? [Colors.green.shade700, Colors.green.shade400]
                : [Colors.red.shade700, Colors.red.shade400];

            return Scaffold(
              appBar: AppBar(
                title: const Text('Personal Cashbook', style: TextStyle(color: Colors.white)),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              drawer: AppDrawer(gradientColors: gradientColors),
              body: Column(
                children: [
                  _buildSummary(context, totalIncome, totalExpense, balance),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: _buildEntryList(entries, balance),
                    ),
                  ),
                ],
              ),
              floatingActionButton: _buildFloatingActionButton(context, cashbookPerson, gradientColors),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            );
          },
        );
      },
    );
  }

  Widget _buildSummary(BuildContext context, double totalIncome, double totalExpense, double balance) {
    final List<Color> gradientColors = balance >= 0
        ? [Colors.green.shade700, Colors.green.shade400]
        : [Colors.red.shade700, Colors.red.shade400];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(child: _buildSummaryCard('Income', totalIncome, Icons.arrow_upward)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard('Expense', totalExpense, Icons.arrow_downward)),
          ],
        ),
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

  Widget _buildEntryList(List<app_transaction.Transaction> entries, double balance) {
    if (entries.isEmpty) {
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
    final sortedEntries = List<app_transaction.Transaction>.from(entries)..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0),
      itemCount: sortedEntries.length + 1,
      itemBuilder: (context, index) {
        if (index == sortedEntries.length) {
          return _buildTotalBalanceFooter(balance);
        }
        final entry = sortedEntries[index];
        final isIncome = entry.type == app_transaction.TransactionType.credit;
        return ListTile(
          leading: Icon(
            isIncome ? Icons.arrow_circle_up_outlined : Icons.arrow_circle_down_outlined,
            color: isIncome ? Colors.green : Colors.red,
            size: 40,
          ),
          title: Text(entry.note ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTotalBalanceFooter(double balance) {
    final List<Color> gradientColors = balance >= 0
        ? [Colors.green.shade700, Colors.green.shade400]
        : [Colors.red.shade700, Colors.red.shade400];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
            '₹${balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, Person cashbookPerson, List<Color> gradientColors) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddEntryDialog(context, cashbookPerson),
      label: const Text('Add Transaction'),
      icon: const Icon(Icons.add),
      backgroundColor: Colors.white,
      foregroundColor: gradientColors.isNotEmpty ? gradientColors[0] : Colors.blue,
    );
  }

  void _showAddEntryDialog(BuildContext context, Person cashbookPerson) {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    app_transaction.TransactionType selectedType = app_transaction.TransactionType.credit;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Cashbook Entry'),
              content: Form(
                key: formKey,
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
                        if (value == null || value.isEmpty) return 'Please enter an amount.';
                        if (double.tryParse(value) == null) return 'Please enter a valid number.';
                        if (double.parse(value) <= 0) return 'Please enter an amount greater than zero.';
                        return null;
                      },
                    ),
                    Row(
                      children: [
                        Radio<app_transaction.TransactionType>(
                          value: app_transaction.TransactionType.credit,
                          groupValue: selectedType,
                          onChanged: (type) => setState(() => selectedType = type!),
                        ),
                        const Text('Income'),
                        Radio<app_transaction.TransactionType>(
                          value: app_transaction.TransactionType.debit,
                          groupValue: selectedType,
                          onChanged: (type) => setState(() => selectedType = type!),
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
                    if (formKey.currentState!.validate()) {
                      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                      final newTransaction = app_transaction.Transaction(
                        personId: cashbookPerson.id!,
                        amount: double.parse(amountController.text),
                        note: descriptionController.text,
                        date: DateTime.now(),
                        type: selectedType,
                      );
                      transactionProvider.addTransaction(newTransaction);
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
