import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/person_provider.dart';
import '../models/transaction.dart' as app_transaction;
import 'package:intl/intl.dart';
import '../models/person.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final transactions = transactionProvider.transactions;

    final groupedTransactions = <DateTime, List<app_transaction.Transaction>>{};
    for (final transaction in transactions) {
      final date = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      if (groupedTransactions[date] == null) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History'),
      ),
      body: transactions.isEmpty
          ? Center(
        child: Text('No transactions yet.'),
      )
          : ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final transactionsOnDate = groupedTransactions[date]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  DateFormat.yMMMMd().format(date),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...transactionsOnDate.map((transaction) {
                return FutureBuilder<Person?>(
                  future: personProvider.getPersonById(transaction.personId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final person = snapshot.data;
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          transaction.type == app_transaction.TransactionType.credit
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: transaction.type == app_transaction.TransactionType.credit
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(person?.name ?? 'Unknown Person'),
                        subtitle: Text(transaction.note ?? ''),
                        trailing: Text(
                          '₹${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: transaction.type == app_transaction.TransactionType.credit
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        onTap: () {
                          // TODO: Implement transaction detail view or edit/delete
                        },
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
