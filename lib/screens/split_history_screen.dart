import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as app_transaction;
import '../providers/person_provider.dart';

class SplitHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Split History'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final splitTransactions = transactionProvider.transactions
              .where((t) => t.splitId != null)
              .toList();

          if (splitTransactions.isEmpty) {
            return Center(
              child: Text('No split expenses yet.'),
            );
          }

          final groupedSplits = <String, List<app_transaction.Transaction>>{};
          for (var transaction in splitTransactions) {
            if (transaction.splitId != null) {
              if (!groupedSplits.containsKey(transaction.splitId)) {
                groupedSplits[transaction.splitId!] = [];
              }
              groupedSplits[transaction.splitId!]!.add(transaction);
            }
          }

          return ListView.builder(
            itemCount: groupedSplits.length,
            itemBuilder: (context, index) {
              final splitId = groupedSplits.keys.elementAt(index);
              final transactions = groupedSplits[splitId]!;
              final firstTransaction = transactions.first;
              final totalAmount = transactions.fold<double>(
                  0, (sum, item) => sum + item.amount);
              final description = firstTransaction.note;
              final date = firstTransaction.date;

              return Card(
                margin: EdgeInsets.all(8.0),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description ?? 'No Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Date: ${date.day}/${date.month}/${date.year}',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      FutureBuilder<List<String>>(
                        future:
                        _getPersonNames(context, transactions),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Text('Error loading names');
                          }
                          return Text(
                            'Split with: ${snapshot.data!.join(', ')}',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<String>> _getPersonNames(BuildContext context,
      List<app_transaction.Transaction> transactions) async {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    await personProvider.loadPersons();
    final names = <String>[];
    for (var transaction in transactions) {
      final person =
      await personProvider.getPersonById(transaction.personId);
      if (person != null) {
        names.add(person.name);
      }
    }
    return names;
  }
}
