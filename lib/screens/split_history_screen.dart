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
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final splitTransactions =
          transactionProvider.transactions.where((t) => t.splitId != null).toList();

          if (splitTransactions.isEmpty) {
            return const Center(
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
                  0, (sum, item) => sum + item.amount * transactions.length);
              final description = firstTransaction.note;
              final date = firstTransaction.date;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description ?? 'No description',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ₹${totalAmount.toStringAsFixed(2)} (Split between ${transactions.length} people)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Participants:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<Widget>>(
                        future: _buildParticipantList(context, transactions),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return const Text('Error loading participants');
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
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Widget>> _buildParticipantList(
      BuildContext context, List<app_transaction.Transaction> transactions) async {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final participants = <Widget>[];

    for (var transaction in transactions) {
      final person = await personProvider.getPersonById(transaction.personId);
      if (person != null) {
        participants.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              '  • ${person.name}: ₹${transaction.amount.toStringAsFixed(2)}',
            ),
          ),
        );
      }
    }

    return participants;
  }
}
