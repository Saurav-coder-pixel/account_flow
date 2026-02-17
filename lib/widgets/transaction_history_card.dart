import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as app_transaction;
import '../providers/person_provider.dart';

class TransactionHistoryCard extends StatelessWidget {
  final dynamic transaction;
  final PersonProvider personProvider;
  final VoidCallback onDelete;

  const TransactionHistoryCard({
    Key? key,
    required this.transaction,
    required this.personProvider,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == app_transaction.TransactionType.credit;
    final color = isCredit ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            isCredit ? Icons.add : Icons.remove,
            color: color,
          ),
        ),
        title: FutureBuilder(
          future: personProvider.getPersonById(transaction.personId),
          builder: (context, snapshot) {
            final personName = snapshot.data?.name ?? 'Unknown';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  personName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '₹${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isCredit ? 'CREDIT' : 'DEBIT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.note != null && transaction.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  transaction.note!,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
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
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: onDelete,
        ),
      ),
    );
  }
}