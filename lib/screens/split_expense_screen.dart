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
  bool _isProcessing = false;

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
    if (!_formKey.currentState!.validate() || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

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

    if (mounted && newPersonNames.isNotEmpty) {
      final confirmedNewPeople = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add New Contacts?'),
          content: Text(
              'These people are not in your contacts: ${newPersonNames.join(', ')}.\n\nWould you like to add them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add & Continue'),
            ),
          ],
        ),
      );
      if (confirmedNewPeople != true) {
        setState(() => _isProcessing = false);
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
        title: const Text('Confirm Expense Split'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Expense: ₹${amount.toStringAsFixed(2)}'),
            Text('Split among: $totalParticipants people'),
            Text('Each share: ₹${splitAmount.toStringAsFixed(2)}'),
            const Divider(height: 20),
            Text('Your cashbook will show a debit of ₹${amount.toStringAsFixed(2)} and a credit of ₹${amountOwedByOthers.toStringAsFixed(2)} for reimbursement.'),
          ],
        ),
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
      setState(() => _isProcessing = false);
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
        type: app_transaction.TransactionType.debit, //This is a debit for them, as they owe you
        splitId: splitId,
      );
      await transactionProvider.addTransaction(otherPersonTransaction);
      await personProvider.refreshPersonBalance(person.id!);
    }

    await personProvider.refreshPersonBalance(cashbookPerson.id!);

    if (mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Expense split successfully! View details in your Cashbook.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).maybePop();
    }
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const List<Color> gradientColors = [Color(0xFF6A1B9A), Color(0xFF8E24AA)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        backgroundColor: gradientColors.first,
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
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [gradientColors.first, gradientColors.last],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter
            )
        ),
        child: _buildSplitForm(),
      ),
    );
  }

  Widget _buildSplitForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildExpenseDetailsCard(),
            const SizedBox(height: 16),
            _buildSplitBetweenCard(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: _isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)) : const Icon(Icons.call_split),
              onPressed: _isProcessing ? null : _splitExpense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF7B1FA2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              label: Text(_isProcessing ? 'Processing...' : 'Split Expense', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Please enter a valid positive amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description for the expense';
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Split With',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ..._buildNameFields(),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _nameControllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Person'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7B1FA2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameControllers[index],
                decoration: InputDecoration(
                    labelText: 'Person ${index + 1}',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_outline)
                ),
                validator: null,
              ),
            ),
            if (_nameControllers.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
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
