import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/person_provider.dart';
import '../models/transaction.dart' as app_transaction;
import 'package:intl/intl.dart';
import 'add_transaction_screen.dart';
import '../models/person.dart';
import '../widgets/app_drawer.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, PersonProvider>(
      builder: (context, transactionProvider, personProvider, child) {
        final transactions = transactionProvider.transactions;
        final persons = personProvider.persons;

        double totalCredit = 0;
        double totalDebit = 0;
        for (var transaction in transactions) {
          if (transaction.type == app_transaction.TransactionType.credit) {
            totalCredit += transaction.amount;
          } else {
            totalDebit += transaction.amount;
          }
        }
        final totalBalance = totalCredit - totalDebit;

        final List<Color> gradientColors = totalBalance >= 0
            ? [Colors.green.shade700, Colors.green.shade400]
            : [Colors.red.shade700, Colors.red.shade400];

        final groupedTransactions = <DateTime, List<app_transaction.Transaction>>{};
        for (final transaction in transactions) {
          final date = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
          if (groupedTransactions[date] == null) {
            groupedTransactions[date] = [];
          }
          groupedTransactions[date]!.add(transaction);
        }

        final sortedDates = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Transaction History', style: TextStyle(color: Colors.white),),
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
          body: transactions.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu, size: 100, color: Colors.grey.shade400),
                const SizedBox(height: 20),
                const Text('No transactions yet.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                Text(
                  'Your transaction history will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
              : _buildTransactionListView(context, sortedDates, groupedTransactions, persons, transactionProvider),
        );
      },
    );
  }

  Widget _buildTransactionListView(
      BuildContext context,
      List<DateTime> sortedDates,
      Map<DateTime, List<app_transaction.Transaction>> groupedTransactions,
      List<Person> persons,
      TransactionProvider transactionProvider
      ) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final transactionsOnDate = groupedTransactions[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                DateFormat.yMMMMd().format(date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
            ),
            ...transactionsOnDate.map((transaction) {
              final person = persons.firstWhere((p) => p.id == transaction.personId, orElse: () => Person(id: 0, name: 'Unknown Person', createdAt: DateTime.now()));
              final isCredit = transaction.type == app_transaction.TransactionType.credit;

              return Dismissible(
                key: Key('history_\${transaction.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete Entry'),
                        content: const Text('Are you sure you want to delete this entry?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  transactionProvider.deleteTransaction(transaction.id!, splitId: transaction.splitId);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted'), backgroundColor: Colors.red,));
                },
                background: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(15)
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_forever, color: Colors.white, size: 30,),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      child: Icon(
                        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isCredit ? Colors.green : Colors.red,
                        size: 30,
                      ),
                    ),
                    title: Text(
                      person.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transaction.note ?? (isCredit ? "Credit" : "Debit"), style: const TextStyle(fontSize: 15),),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('hh:mm a').format(transaction.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${isCredit ? '+' : '-'} ₹${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: isCredit ? Colors.green : Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionScreen(person: person, transaction: transaction),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
            const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16,)
          ],
        );
      },
    );
  }
}
