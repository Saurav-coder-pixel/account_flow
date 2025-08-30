import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/person_provider.dart';
import '../models/person.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as app_transaction;
import 'split_history_screen.dart';

class SplitExpenseScreen extends StatefulWidget {
  @override
  _SplitExpenseScreenState createState() => _SplitExpenseScreenState();
}

class _SplitExpenseScreenState extends State<SplitExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _namesController = TextEditingController();
  final _uuid = Uuid();

  void _splitExpense() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final description = _descriptionController.text;
      final names = _namesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (amount <= 0 || names.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Please enter a valid amount and at least one person\'s name.'),
          ),
        );
        return;
      }

      final splitAmount = amount / names.length;
      final personProvider = Provider.of<PersonProvider>(context, listen: false);
      final transactionProvider =
      Provider.of<TransactionProvider>(context, listen: false);
      final splitId = _uuid.v4();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Split Expense'),
            content: Text(
                'This will add a debit of ₹${splitAmount.toStringAsFixed(2)} to each person for "$description".'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final List<Person> transactionPersons = [];
                  final List<String> newPersonNames = [];

                  for (final name in names) {
                    try {
                      final existingPerson = personProvider.persons
                          .firstWhere((p) => p.name.toLowerCase() == name.toLowerCase());
                      transactionPersons.add(existingPerson);
                    } catch (e) {
                      newPersonNames.add(name);
                    }
                  }

                  if (newPersonNames.isNotEmpty) {
                    for (final name in newPersonNames) {
                      await personProvider.addPerson(name);
                    }
                    await personProvider.loadPersons();
                    for (final name in newPersonNames) {
                      try {
                        final newPerson = personProvider.persons
                            .firstWhere((p) => p.name.toLowerCase() == name.toLowerCase());
                        transactionPersons.add(newPerson);
                      } catch (e) {
                        // Should not happen, but as a safeguard
                        print('Could not find newly created person: $name');
                      }
                    }
                  }

                  for (final person in transactionPersons) {
                    final newTransaction = app_transaction.Transaction(
                      personId: person.id!,
                      amount: splitAmount,
                      type: app_transaction.TransactionType.debit,
                      note: description,
                      date: DateTime.now(),
                      splitId: splitId, // Add splitId to transaction
                    );
                    await transactionProvider.addTransaction(newTransaction);
                  }

                  Navigator.pop(context);
                  _amountController.clear();
                  _descriptionController.clear();
                  _namesController.clear();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Expense split successfully!')),
                  );
                },
                child: Text('Confirm'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Split Expense'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SplitHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                    labelText: 'Amount', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _namesController,
                decoration: InputDecoration(
                  labelText: 'People to Split With',
                  hintText: 'Enter names, separated by commas',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter at least one name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _splitExpense,
        label: Text('Split'),
        icon: Icon(Icons.call_split),
      ),
    );
  }
}
