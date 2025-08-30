import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/person_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as app_transaction;
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';

class CashbookScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cashbook'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final transactions = transactionProvider.transactions;
          if (transactions.isEmpty) {
            return Center(
              child: Text('No transactions yet.'),
            );
          }

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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.green.shade700,
                            Colors.green.shade400
                          ]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Total Credit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '₹${totalCredit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.red.shade700,
                            Colors.red.shade400
                          ]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Total Debit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '₹${totalDebit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppBar(
                title: Text(
                  'Total Balance: ₹${totalBalance.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                automaticallyImplyLeading: false,
                centerTitle: true,
                elevation: 0,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return TransactionCard(
                      transaction: transaction,
                      onDelete: () => _deleteTransaction(context, transaction),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _selectPersonAndAddTransaction(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _selectPersonAndAddTransaction(BuildContext context) {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final persons = personProvider.persons;

    if (persons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add a person first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Person for Transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: persons.map((person) {
                return ListTile(
                  title: Text(person.name),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTransactionScreen(person: person),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _deleteTransaction(
      BuildContext context, app_transaction.Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Transaction'),
          content: Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await Provider.of<TransactionProvider>(context, listen: false)
                    .deleteTransaction(transaction.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Transaction deleted successfully')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
