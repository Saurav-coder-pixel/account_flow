import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as app_transaction;
import 'add_transaction_screen.dart';
import '../widgets/transaction_card.dart';

class PersonDetailScreen extends StatelessWidget {
  final Person person;

  const PersonDetailScreen({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final personTransactions =
            transactionProvider.getTransactionsForPerson(person.id!);

        double totalCredit = 0;
        double totalDebit = 0;
        for (var t in personTransactions) {
          if (t.type == app_transaction.TransactionType.credit) {
            totalCredit += t.amount;
          } else {
            totalDebit += t.amount;
          }
        }
        final balance = totalCredit - totalDebit;

        final List<Color> gradientColors = balance >= 0
            ? [Colors.green.shade700, Colors.green.shade400]
            : [Colors.red.shade700, Colors.red.shade400];

        return Scaffold(
          appBar: AppBar(
            title: Text(person.name),
            foregroundColor: Colors.white,
            elevation: 0,
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
          body: Column(
            children: [
              _buildSummaryHeader(totalCredit, totalDebit, balance),
              const Divider(height: 1),
              Expanded(
                child: personTransactions.isEmpty
                    ? const Center(child: Text('No transactions yet.'))
                    : _buildTransactionsList(
                        context, personTransactions, transactionProvider),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(person: person),
                ),
              );
            },
            label: const Text('Add Entry'),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.blue,
          ),
        );
      },
    );
  }

  Widget _buildSummaryHeader(double credit, double debit, double balance) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Row(
            children: [
              _buildSummaryItem("You will give", credit, Colors.green),
              const SizedBox(width: 16),
              _buildSummaryItem("You will get", debit, Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: balance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: balance >= 0
                      ? Colors.green.shade200
                      : Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Running Balance",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                Text(
                  "₹${balance.abs().toStringAsFixed(2)} ${balance >= 0 ? '(You will give)' : '(You will get)'}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(
              "₹${amount.toStringAsFixed(2)}",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
      BuildContext context,
      List<app_transaction.Transaction> transactions,
      TransactionProvider provider) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions yet.'));
    }

    // Sort transactions chronologically for grouping
    final sortedTransactions = List<app_transaction.Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<Widget> items = [];
    DateTime? lastTimestamp;

    for (var i = 0; i < sortedTransactions.length; i++) {
      final t = sortedTransactions[i];

      // Add a divider if it's the first item or far from the last one (e.g., > 1 hour)
      if (lastTimestamp == null ||
          t.date.difference(lastTimestamp).abs().inMinutes > 60) {
        items.add(_buildTimestampDivider(t.date));
      }

      items.add(
        Dismissible(
          key: Key(t.id.toString()),
          direction: DismissDirection.horizontal,
          onDismissed: (direction) {
            provider.deleteTransaction(t.id!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Transaction deleted"),
                action: SnackBarAction(
                  label: "Undo",
                  onPressed: () {
                    provider.addTransaction(t);
                  },
                ),
              ),
            );
          },
          background: Container(
            color: Colors.red.withOpacity(0.1),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          secondaryBackground: Container(
            color: Colors.red.withOpacity(0.1),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          child: TransactionCard(
            transaction: t,
            personName: person.name,
            onDelete: () {
              provider.deleteTransaction(t.id!);
            },
          ),
        ),
      );
      lastTimestamp = t.date;
    }

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _buildTimestampDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              DateFormat('EEEE, h:mm a').format(date),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
