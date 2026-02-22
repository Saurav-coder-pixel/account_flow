import 'package:account_flow/providers/currency_provider.dart';
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
    final currencyProvider = Provider.of<CurrencyProvider>(context);

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
              drawer: AppDrawer(gradientColors: gradientColors),
              body: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(balance, gradientColors, context, currencyProvider.currencySymbol),
                  _buildSummaryCards(totalIncome, totalExpense, balance, currencyProvider.currencySymbol),
                  _buildSectionHeader(context, 'Recent Transactions'),
                  _buildEntryList(context, entries, transactionProvider, currencyProvider.currencySymbol),
                ],
              ),
              floatingActionButton: _buildFloatingActionButton(context, cashbookPerson, gradientColors, currencyProvider.currencySymbol),
            );
          },
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(
      double totalBalance, List<Color> gradientColors, BuildContext context, String currencySymbol) {
    return SliverAppBar(
      expandedHeight: 150.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          '$currencySymbol${totalBalance.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.only(top: 50.0),
            child: Column(
              children: [
                Text(
                  'Personal Cashbook',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Current Balance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSummaryCards(double totalIncome, double totalExpense, double balance, String currencySymbol) {
    final List<Color> gradientColors = balance >= 0
        ? [Colors.green.shade700, Colors.green.shade400]
        : [Colors.red.shade700, Colors.red.shade400];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildSummaryCard(
              'Total Income',
              '$currencySymbol${totalIncome.toStringAsFixed(2)}',
              [Colors.green.shade700, Colors.green.shade400],
              Icons.arrow_upward,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              'Total Expense',
              '$currencySymbol${totalExpense.toStringAsFixed(2)}',
              [Colors.red.shade700, Colors.red.shade400],
              Icons.arrow_downward,
            ),
          ],
        ),
      ),
    );
  }

  Expanded _buildSummaryCard(
      String title, String amount, List<Color> colors, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Icon(icon, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }


  SliverToBoxAdapter _buildSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEntryList(BuildContext context, List<app_transaction.Transaction> entries, TransactionProvider transactionProvider, String currencySymbol) {
    if (entries.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('No transactions yet.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                'Tap the "Add Transaction" button to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    final sortedEntries = List<app_transaction.Transaction>.from(entries)..sort((a, b) => b.date.compareTo(a.date));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final entry = sortedEntries[index];
          final isIncome = entry.type == app_transaction.TransactionType.credit;
          return Dismissible(
            key: Key(entry.id.toString()),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete Transaction'),
                    content: const Text('Are you sure you want to delete this transaction?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) {
              transactionProvider.deleteTransaction(entry.id!, splitId: entry.splitId);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Transaction deleted"), backgroundColor: Colors.red)
              );
            },
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(15)
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 30),
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  child: Icon(
                    isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: isIncome ? Colors.green : Colors.red,
                    size: 28,
                  ),
                ),
                title: Text(entry.note ?? 'No description', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(DateFormat('MMM dd, yyyy • hh:mm a').format(entry.date), style: TextStyle(color: Colors.grey.shade600)),
                trailing: Text(
                  '${isIncome ? '+' : '-'} $currencySymbol${entry.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        },
        childCount: sortedEntries.length,
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, Person cashbookPerson, List<Color> gradientColors, String currencySymbol) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddEntryDialog(context, cashbookPerson, currencySymbol),
      label: const Text('Add Transaction'),
      icon: const Icon(Icons.add),
      backgroundColor: gradientColors.first,
      foregroundColor: Colors.white,
    );
  }

  void _showAddEntryDialog(BuildContext context, Person cashbookPerson, String currencySymbol) {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('New Transaction', textAlign: TextAlign.center),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(labelText: 'Amount', prefixText: currencySymbol, border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter an amount.';
                        if (double.tryParse(value) == null) return 'Please enter a valid number.';
                        if (double.parse(value) <= 0) return 'Please enter an amount greater than zero.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text("Type:"),
                        ChoiceChip(
                          label: const Text('Income'),
                          selected: selectedType == app_transaction.TransactionType.credit,
                          onSelected: (selected) {
                            if (selected) setState(() => selectedType = app_transaction.TransactionType.credit);
                          },
                          selectedColor: Colors.green.shade100,
                        ),
                        ChoiceChip(
                          label: const Text('Expense'),
                          selected: selectedType == app_transaction.TransactionType.debit,
                          onSelected: (selected) {
                            if (selected) setState(() => selectedType = app_transaction.TransactionType.debit);
                          },
                          selectedColor: Colors.red.shade100,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Transaction added successfully!"), backgroundColor: Colors.green)
                      );
                    }
                  },
                  label: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
