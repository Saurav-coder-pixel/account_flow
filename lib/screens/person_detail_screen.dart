import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as app_transaction;

class PersonDetailScreen extends StatelessWidget {
  final Person person;

  const PersonDetailScreen({required this.person});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final personTransactions = transactionProvider.getTransactionsForPerson(person.id!);

    double balance = transactionProvider.calculateBalance(personTransactions);

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: personTransactions.length,
              itemBuilder: (context, index) {
                final transaction = personTransactions[index];
                return ListTile(
                  leading: Icon(transaction.type == app_transaction.TransactionType.credit
                      ? Icons.arrow_downward
                      : Icons.arrow_upward),
                  title: Text('₹${transaction.amount.toStringAsFixed(2)}'),
                  subtitle: Text(transaction.note ?? ''),
                  trailing: Text(
                    '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
