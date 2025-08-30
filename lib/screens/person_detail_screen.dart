import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/person.dart';
import '../models/transaction.dart' as app_transaction;
import '../providers/transaction_provider.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  final Person person;

  PersonDetailScreen({required this.person});

  @override
  _PersonDetailScreenState createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false)
          .loadTransactionsByPersonId(widget.person.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final transactions =
          transactionProvider.getTransactionsForPerson(widget.person.id!);
          final balance = transactionProvider.calculateBalance(transactions);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(widget.person.name,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700
                    ),),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          child: Text(
                            widget.person.name.isNotEmpty
                                ? widget.person.name[0]
                                : '',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          balance >= 0
                              ? '₹${balance.toStringAsFixed(2)}'
                              : '-₹${balance.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          balance >= 0 ? 'Credit' : 'Debit',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (transactions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No transactions yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap + to add your first transaction',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final transaction = transactions[index];
                    return TransactionCard(
                      transaction: transaction,
                      onDelete: () => _deleteTransaction(transaction),
                    );
                  },
                  childCount:
                  transactions.isEmpty ? 1 : transactions.length,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddTransactionScreen(person: widget.person),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _deleteTransaction(app_transaction.Transaction transaction) {
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
