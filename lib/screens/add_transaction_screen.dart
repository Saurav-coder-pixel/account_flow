import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/person.dart';
import '../models/transaction.dart' as app_transaction;
import '../providers/transaction_provider.dart';
import '../providers/person_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final Person person;
  final app_transaction.Transaction? transaction;

  AddTransactionScreen({required this.person, this.transaction});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  app_transaction.TransactionType _selectedType = app_transaction.TransactionType.credit;
  DateTime _selectedDate = DateTime.now();
  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final transaction = widget.transaction!;
      _amountController.text = transaction.amount.toString();
      _noteController.text = transaction.note ?? '';
      _selectedType = transaction.type;
      _selectedDate = transaction.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, PersonProvider>(
      builder: (context, transactionProvider, personProvider, child) {
        final transactions = transactionProvider.transactions;
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

        final List<Color> gradientColors = totalBalance >= 0
            ? [Colors.green.shade700, Colors.green.shade400]
            : [Colors.red.shade700, Colors.red.shade400];

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                _buildHeader(context),
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
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Transaction for ${widget.person.name}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Transaction Type',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: RadioListTile<app_transaction.TransactionType>(
                                              title: const Text('Credit'),
                                              subtitle: const Text('Money given'),
                                              value: app_transaction.TransactionType.credit,
                                              groupValue: _selectedType,
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedType = value!;
                                                });
                                              },
                                              activeColor: Colors.green,
                                            ),
                                          ),
                                          Expanded(
                                            child: RadioListTile<app_transaction.TransactionType>(
                                              title: const Text('Debit'),
                                              subtitle: const Text('Money received'),
                                              value: app_transaction.TransactionType.debit,
                                              groupValue: _selectedType,
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedType = value!;
                                                });
                                              },
                                              activeColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _amountController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          labelText: 'Amount',
                                          hintText: 'Enter amount',
                                          prefixIcon: const Icon(Icons.currency_rupee),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Please enter an amount';
                                          }
                                          final amount = double.tryParse(value);
                                          if (amount == null || amount <= 0) {
                                            return 'Please enter a valid amount';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _noteController,
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          labelText: 'Note (Optional)',
                                          hintText: 'Enter transaction details',
                                          prefixIcon: const Icon(Icons.note),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ListTile(
                                        leading: const Icon(Icons.calendar_today),
                                        title: const Text('Date'),
                                        subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                                        onTap: _selectDate,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: BorderSide(color: Colors.grey.shade400),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _saveTransaction,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedType == app_transaction.TransactionType.credit
                                      ? Colors.green
                                      : Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _isEditing
                                      ? 'Save Changes'
                                      : 'Add ${_selectedType == app_transaction.TransactionType.credit ? 'Credit' : 'Debit'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                Text(
                  _isEditing ? 'Edit Transaction' : 'Add Transaction',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _deleteTransaction,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      try {
        final amount = double.parse(_amountController.text);
        final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

        if (_isEditing) {
          final updatedTransaction = widget.transaction!.copyWith(
            amount: amount,
            note: note,
            date: _selectedDate,
            type: _selectedType,
          );
          await Provider.of<TransactionProvider>(context, listen: false)
              .updateTransaction(updatedTransaction);
        } else {
          final newTransaction = app_transaction.Transaction(
            personId: widget.person.id!,
            amount: amount,
            note: note,
            date: _selectedDate,
            type: _selectedType,
          );
          await Provider.of<TransactionProvider>(context, listen: false)
              .addTransaction(newTransaction);
        }

        await Provider.of<PersonProvider>(context, listen: false)
            .refreshPersonBalance(widget.person.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction ${_isEditing ? 'updated' : 'added'} successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isEditing ? 'update' : 'add'} transaction. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteTransaction() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<TransactionProvider>(context, listen: false)
            .deleteTransaction(widget.transaction!.id!);

        await Provider.of<PersonProvider>(context, listen: false)
            .refreshPersonBalance(widget.person.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete transaction. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
