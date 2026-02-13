import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/person_provider.dart';
import '../models/transaction.dart' as app_transaction;
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, PersonProvider>(
      builder: (context, transactionProvider, personProvider, child) {
        final transactions = transactionProvider.transactions;
        
        // Map person IDs to names for instant lookup
        final personMap = {
          for (var p in personProvider.persons) p.id: p.name
        };

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
            title: const Text('Transaction History'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          body: transactions.isEmpty
              ? const Center(
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
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text(
                            DateFormat.yMMMMd().format(date),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        ...transactionsOnDate.map((transaction) {
                          final personName = personMap[transaction.personId] ?? 'Unknown Person';
                          final isCredit = transaction.type == app_transaction.TransactionType.credit;

                          return Dismissible(
                            key: Key('history_${transaction.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              transactionProvider.deleteTransaction(transaction.id!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Transaction deleted')),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isCredit ? Colors.green.shade50 : Colors.red.shade50,
                                  child: Icon(
                                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isCredit ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  personName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(transaction.note ?? (isCredit ? "Credit" : "Debit")),
                                trailing: Text(
                                  '₹${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isCredit ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}
