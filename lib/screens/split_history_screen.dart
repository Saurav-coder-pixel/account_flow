import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart' as app_transaction;
import '../providers/person_provider.dart';
import '../providers/transaction_provider.dart';

class SplitHistoryScreen extends StatelessWidget {
  const SplitHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split History'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final splitTransactions = transactionProvider.transactions
              .where((t) => t.splitId != null)
              .toList();

          if (splitTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 100, color: Colors.grey.shade400),
                  const SizedBox(height: 20),
                  const Text(
                    'No split expenses found.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
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
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            itemCount: groupedSplits.length,
            itemBuilder: (context, index) {
              final splitId = groupedSplits.keys.elementAt(index);
              final transactions = groupedSplits[splitId]!;
              final firstTransaction = transactions.first;
              final totalAmount =
              transactions.fold<double>(0, (sum, item) => sum + item.amount);
              final description = firstTransaction.note;
              final date = firstTransaction.date;

              return Dismissible(
                key: Key(splitId),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: const Text(
                            'Are you sure you want to delete this split expense? This action cannot be undone.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  transactionProvider.deleteTransaction(firstTransaction.id!,
                      splitId: splitId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Split expense deleted.'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                },
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
                ),
                child: Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                description ?? 'No description',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '₹${totalAmount.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Split between ${transactions.length} people',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('E, MMM dd, yyyy • hh:mm a').format(date),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey.shade500),
                        ),
                        const Divider(height: 30),
                        const Text(
                          'Participants',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<Widget>>(
                          future:
                          _buildParticipantList(context, transactions),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return const Text(
                                  'Error loading participants');
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: snapshot.data ?? [],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Widget>> _buildParticipantList(BuildContext context,
      List<app_transaction.Transaction> transactions) async {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final participants = <Widget>[];

    for (var transaction in transactions) {
      final person = await personProvider.getPersonById(transaction.personId);
      if (person != null) {
        participants.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                  Theme.of(context).primaryColor.withAlpha(40),
                  child: Text(
                    person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(person.name,
                        style: const TextStyle(fontSize: 16))),
                Text('₹${transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      }
    }

    return participants;
  }
}
