import 'package:flutter/material.dart';
import '../models/transaction.dart' as app_transaction;
import '../helpers/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  List<app_transaction.Transaction> _transactions = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<app_transaction.Transaction> get transactions => _transactions;

  Future<void> loadTransactionsByPersonId(int personId) async {
    _transactions = await _dbHelper.getTransactionsByPersonId(personId);
    notifyListeners();
  }

  Future<void> loadAllTransactions() async {
    _transactions = await _dbHelper.getAllTransactions();
    notifyListeners();
  }

  Future<void> addTransaction(app_transaction.Transaction transaction) async {
    final id = await _dbHelper.insertTransaction(transaction);
    final newTransaction = transaction.copyWith(id: id);
    _transactions.insert(0, newTransaction); // Add to beginning for latest first
    notifyListeners();
  }

  Future<void> updateTransaction(app_transaction.Transaction transaction) async {
    await _dbHelper.updateTransaction(transaction);
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(int transactionId) async {
    await _dbHelper.deleteTransaction(transactionId);
    _transactions.removeWhere((transaction) => transaction.id == transactionId);
    notifyListeners();
  }

  Future<void> clearAllTransactions() async {
    await _dbHelper.clearAllData();
    _transactions.clear();
    notifyListeners();
  }

  List<app_transaction.Transaction> getTransactionsForPerson(int personId) {
    return _transactions.where((t) => t.personId == personId).toList();
  }

  List<app_transaction.Transaction> getTransactionsBySplitId(String splitId) {
    return _transactions.where((t) => t.splitId == splitId).toList();
  }

  double calculateBalance(List<app_transaction.Transaction> transactions) {
    double balance = 0.0;
    for (var transaction in transactions) {
      if (transaction.type == app_transaction.TransactionType.credit) {
        balance += transaction.amount;
      } else {
        balance -= transaction.amount;
      }
    }
    return balance;
  }
}
