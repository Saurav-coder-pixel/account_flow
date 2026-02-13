import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';
import '../models/transaction.dart' as app_transaction;
import '../providers/person_provider.dart';
import '../providers/transaction_provider.dart';
import './split_history_screen.dart';

class SplitExpenseScreen extends StatefulWidget {
  const SplitExpenseScreen({super.key});

  @override
  _SplitExpenseScreenState createState() => _SplitExpenseScreenState();
}

class _SplitExpenseScreenState extends State<SplitExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _nameControllers = [TextEditingController()];
  static const _uuid = Uuid();

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
          const SnackBar(
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
            title: const Text('Split Expense'),
            content: Text(
                'This will add a debit of ₹${splitAmount.toStringAsFixed(2)} to each person for "$description".'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
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
                          title: const Text('New People Found'),
                          content: Text(
                              'The following people are not in your contacts: ${newPersonNames.join(', ')}. Do you want to add them?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Add and Continue'),
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
                    const SnackBar(
                      content: Text('Expense split successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Confirm'),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _buildSplitForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text(
                  'Split Expense',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
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
      ),
    );
  }


  Widget _buildSplitForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildExpenseDetailsCard(),
              const SizedBox(height: 16),
              _buildSplitBetweenCard(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _splitExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Split Expense', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
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
    );
  }

  Widget _buildSplitBetweenCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Split Between',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._buildNameFields(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _nameControllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add, color: Color(0xFF6A1B9A)),
                label: const Text('Add Person', style: TextStyle(color: Color(0xFF6A1B9A))),
              ),
            ),
          ],
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
                  border: const OutlineInputBorder(),
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
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
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
