import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';
import '../models/transaction.dart' as app_transaction;
import '../providers/person_provider.dart';
import '../providers/transaction_provider.dart';
import './split_history_screen.dart';

class SplitExpenseScreen extends StatefulWidget {
  @override
  _SplitExpenseScreenState createState() => _SplitExpenseScreenState();
}

class _SplitExpenseScreenState extends State<SplitExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _nameControllers = [TextEditingController()];
  final _uuid = Uuid();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _splitExpense() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final description = _descriptionController.text;
      final names = _nameControllers
          .map((e) => e.text.trim())
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
                    final existingPerson =
                    await personProvider.findPersonByName(name);
                    if (existingPerson != null) {
                      transactionPersons.add(existingPerson);
                    } else {
                      newPersonNames.add(name);
                    }
                  }

                  if (newPersonNames.isNotEmpty) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('New People Found'),
                          content: Text(
                              'The following people are not in your contacts: ${newPersonNames.join(', ')}. Do you want to add them?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Add and Continue'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmed == true) {
                      for (final name in newPersonNames) {
                        final newPerson = Person(
                          name: name,
                          createdAt: DateTime.now(),
                        );
                        final addedPerson =
                        await personProvider.addPerson(newPerson);
                        transactionPersons.add(addedPerson);
                      }
                    } else {
                      Navigator.pop(context); // Close the split confirmation dialog
                      return;
                    }
                  }

                  for (final person in transactionPersons) {
                    final transaction = app_transaction.Transaction(
                      personId: person.id!,
                      amount: splitAmount,
                      note: description,
                      date: DateTime.now(),
                      type: app_transaction.TransactionType.debit,
                      splitId: splitId,
                    );
                    await transactionProvider.addTransaction(transaction);
                    await personProvider.refreshPersonBalance(person.id!);
                  }

                  Navigator.pop(context); // Close the split confirmation dialog
                  Navigator.pop(context); // Go back from SplitExpenseScreen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Expense split successfully!'),
                      backgroundColor: Colors.green,
                    ),
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
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder()),
                          keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
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
                              labelText: 'Description',
                              border: OutlineInputBorder()),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Split Between',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        ..._buildNameFields(),
                        SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _nameControllers.add(TextEditingController());
                            });
                          },
                          icon: Icon(Icons.add),
                          label: Text('Add Person'),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _splitExpense,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Split Expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNameFields() {
    return List.generate(_nameControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameControllers[index],
                decoration: InputDecoration(
                  labelText: 'Person ${index + 1}',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (index == 0 && (value == null || value.isEmpty)) {
                    return 'Please enter at least one person\'s name';
                  }
                  return null;
                },
              ),
            ),
            if (_nameControllers.length > 1)
              IconButton(
                icon: Icon(Icons.remove_circle),
                onPressed: () {
                  setState(() {
                    _nameControllers[index].dispose();
                    _nameControllers.removeAt(index);
                  });
                },
              ),
          ],
        ),
      );
    });
  }
}
