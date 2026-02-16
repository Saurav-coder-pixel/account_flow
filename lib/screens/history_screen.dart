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
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No transactions yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text(
                  'Your transaction history will appear here.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              final person = persons.firstWhere((p) => p.id == transaction.personId, orElse: () => Person(id: 0, name: 'Unknown Person', createdAt: DateTime.now()));
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
                    SnackBar(
                      content: const Text("Transaction deleted"),
                      action: SnackBarAction(
                        label: "Undo",
                        onPressed: () {
                          transactionProvider.addTransaction(transaction);
                        },
                      ),
                    ),
                  );
                },
                child: ListTile(
                  leading: Icon(
                    isCredit ? Icons.arrow_circle_down_outlined : Icons.arrow_circle_up_outlined,
                    color: isCredit ? Colors.green : Colors.red,
                    size: 40,
                  ),
                  title: Text(
                    person.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(transaction.note ?? (isCredit ? "Credit" : "Debit")),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('hh:mm a').format(transaction.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${isCredit ? '+' : '-'} ₹${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
