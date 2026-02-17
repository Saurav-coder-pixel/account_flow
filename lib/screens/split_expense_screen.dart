import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';
import '../models/transaction.dart' as app_transaction;
import '../providers/person_provider.dart';
import '../providers/transaction_provider.dart';
import './split_history_screen.dart';
import '../widgets/app_drawer.dart';

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Capture the ScaffoldMessengerState before the async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final description = _descriptionController.text;
    final otherPersonNames =
    _nameControllers.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();

    final List<String> newPersonNames = [];
    for (final name in otherPersonNames) {
      final existingPerson = await personProvider.findPersonByName(name);
      if (existingPerson == null) {
        newPersonNames.add(name);
      }
    }

    if (!mounted) return;

    if (newPersonNames.isNotEmpty) {
      final confirmedNewPeople = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('New People Found'),
          content: Text(
              'The following people are not in your contacts: ${newPersonNames.join(', ')}. Do you want to add them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add and Continue'),
            ),
          ],
        ),
      );
      if (confirmedNewPeople != true) {
        return;
      }
    }

    if (!mounted) return;

    final totalParticipants = otherPersonNames.length + 1;
    final splitAmount = amount / totalParticipants;
    final amountOwedByOthers = splitAmount * otherPersonNames.length;

    final confirmedSplit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Split'),
        content: Text('Total Expense: ₹${amount.toStringAsFixed(2)}\n'
            'Split among: $totalParticipants people (including you)\n'
            'Each person\'s share: ₹${splitAmount.toStringAsFixed(2)}\n\n'
            'Your personal cashbook will show a debit of ₹${amount.toStringAsFixed(2)} for the full expense, and a credit of ₹${amountOwedByOthers.toStringAsFixed(2)} for the amount owed to you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmedSplit != true) {
      return;
    }

    if (!mounted) return;

    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final splitId = const Uuid().v4();

    const cashbookPersonName = 'Personal Cashbook';
    Person? cashbookPerson =
    await personProvider.findPersonByName(cashbookPersonName);
    cashbookPerson ??= await personProvider
        .addPerson(Person(name: cashbookPersonName, createdAt: DateTime.now(), isCashbook: true,));

    final totalExpenseTransaction = app_transaction.Transaction(
      personId: cashbookPerson.id!,
      amount: amount,
      note: 'Split: $description',
      date: DateTime.now(),
      type: app_transaction.TransactionType.debit,
      splitId: splitId,
    );
    await transactionProvider.addTransaction(totalExpenseTransaction);

    if (amountOwedByOthers > 0) {
      final reimbursementTransaction = app_transaction.Transaction(
        personId: cashbookPerson.id!,
        amount: amountOwedByOthers,
        note: 'Reimbursement for: $description',
        date: DateTime.now(),
        type: app_transaction.TransactionType.credit,
        splitId: splitId,
      );
      await transactionProvider.addTransaction(reimbursementTransaction);
    }

    for (final name in otherPersonNames) {
      Person? person = await personProvider.findPersonByName(name);
      person ??= await personProvider
          .addPerson(Person(name: name, createdAt: DateTime.now(), isCashbook: false,));

      final otherPersonTransaction = app_transaction.Transaction(
        personId: person.id!,
        amount: splitAmount,
        note: 'Owed to you for: $description',
        date: DateTime.now(),
        type: app_transaction.TransactionType.debit,
        splitId: splitId,
      );
      await transactionProvider.addTransaction(otherPersonTransaction);
      await personProvider.refreshPersonBalance(person.id!); 
    }

    await personProvider.refreshPersonBalance(cashbookPerson.id!); 

    if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Expense split successfully! View details in your Cashbook.'),
    backgroundColor: Colors.green,
  ),
);

Navigator.of(context).maybePop();
  }

 @override
  Widget build(BuildContext context) {
    const List<Color> gradientColors = [Color(0xFF6A1B9A), Color(0xFF8E24AA)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Expense', style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFF7B1FA2),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SplitHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(gradientColors: gradientColors),
      body: Container(
        color: const Color(0xFFF3E5F5),
        child: _buildSplitForm(),
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
                  backgroundColor: const Color(0xFF7B1FA2),
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
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.mic_none),
              ),
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
              decoration: InputDecoration(
                labelText: 'Description',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
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
            Row(
              children: [
                Text(
                  'Split with (optional)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                )
              ],
            ),
            const SizedBox(height: 16),
            ..._buildNameFields(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _nameControllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF7B1FA2)),
                label: const Text('Add Person', style: TextStyle(color: Color(0xFF7B1FA2))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7B1FA2), width: 1, style: BorderStyle.solid),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                validator: null,
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
