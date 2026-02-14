import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as app_transaction;
import 'add_transaction_screen.dart';

class PersonDetailScreen extends StatelessWidget {
  final Person person;

  const PersonDetailScreen({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final personTransactions = transactionProvider.getTransactionsForPerson(person.id!);

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
                    : _buildTransactionsList(context, personTransactions, transactionProvider),
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
              _buildSummaryItem("Total Credit", credit, Colors.green),
              const SizedBox(width: 16),
              _buildSummaryItem("Total Debit", debit, Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: balance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: balance >= 0 ? Colors.green.shade200 : Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Running Balance",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                Text(
                  "₹${balance.abs().toStringAsFixed(2)} ${balance >= 0 ? '(Credit)' : '(Debit)'}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
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
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(
              "₹${amount.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, List<app_transaction.Transaction> transactions, TransactionProvider provider) {
    return ListView.builder(
      itemCount: transactions.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final t = transactions[index];
        final isCredit = t.type == app_transaction.TransactionType.credit;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCredit ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(
                isCredit ? Icons.add : Icons.remove,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              "₹${t.amount.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(t.note ?? (isCredit ? "Credit Entry" : "Debit Entry")),
            trailing: Text(DateFormat('dd MMM, hh:mm a').format(t.date)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(person: person, transaction: t),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
