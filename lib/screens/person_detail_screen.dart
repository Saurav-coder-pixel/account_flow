import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as app_transaction;
import 'add_transaction_screen.dart';

class PersonDetailScreen extends StatelessWidget {
  final Person person;

  const PersonDetailScreen({required this.person});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final personTransactions =
    transactionProvider.getTransactionsForPerson(person.id!);
    double balance = transactionProvider.calculateBalance(personTransactions);

    final bool isCredit = balance >= 0;
    final List<Color> gradientColors = isCredit
        ? [Colors.green.shade700, Colors.green.shade400]
        : [Colors.red.shade700, Colors.red.shade400];

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
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
          _buildBalanceCard(balance, gradientColors),
          _buildTransactionsHeader(context),
          Expanded(
            child: personTransactions.isEmpty
                ? Center(
              child: Text('No transactions yet.'),
            )
                : _buildTransactionsList(personTransactions),
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
        label: Text('Add Transaction'),
        icon: Icon(Icons.add),
        backgroundColor: gradientColors[0],
      ),
    );
  }

  Widget _buildBalanceCard(double balance, List<Color> gradientColors) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance:',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
      List<app_transaction.Transaction> transactions) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isCredit =
            transaction.type == app_transaction.TransactionType.credit;
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCredit ? Colors.green : Colors.red,
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.white,
              ),
            ),
            title: Text(
              '₹${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: transaction.note != null && transaction.note!.isNotEmpty
                ? Text(transaction.note!)
                : null,
            trailing: Text(
              DateFormat('MMM dd, yyyy').format(transaction.date),
            ),
          ),
        );
      },
    );
  }
}
