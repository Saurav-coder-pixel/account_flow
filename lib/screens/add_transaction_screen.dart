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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction for ${widget.person.name}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Transaction Type
                      Text(
                        'Transaction Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<app_transaction.TransactionType>(
                              title: Text('Credit'),
                              subtitle: Text('Money given'),
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
                              title: Text('Debit'),
                              subtitle: Text('Money received'),
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

                      SizedBox(height: 16),

                      // Amount
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: 'Enter amount',
                          prefixIcon: Icon(Icons.currency_rupee),
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

                      SizedBox(height: 16),

                      // Note
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Note (Optional)',
                          hintText: 'Enter transaction details',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Date
                      ListTile(
                        leading: Icon(Icons.calendar_today),
                        title: Text('Date'),
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

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == app_transaction.TransactionType.credit
                      ? Colors.green
                      : Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isEditing
                      ? 'Save Changes'
                      : 'Add ${_selectedType == app_transaction.TransactionType.credit ? 'Credit' : 'Debit'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
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
        title: Text('Delete Transaction'),
        content: Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
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
          SnackBar(
            content: Text('Transaction deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete transaction. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}