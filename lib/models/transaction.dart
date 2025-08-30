enum TransactionType { credit, debit }

class Transaction {
  final int? id;
  final int personId;
  final double amount;
  final String? note;
  final DateTime date;
  final TransactionType type;
  final String? splitId;

  Transaction({
    this.id,
    required this.personId,
    required this.amount,
    this.note,
    required this.date,
    required this.type,
    this.splitId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_id': personId,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'type': type.toString().split('.').last,
      'split_id': splitId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      personId: map['person_id'],
      amount: map['amount'].toDouble(),
      note: map['note'],
      date: DateTime.parse(map['date']),
      type: map['type'] == 'credit' ? TransactionType.credit : TransactionType.debit,
      splitId: map['split_id'],
    );
  }

  Transaction copyWith({
    int? id,
    int? personId,
    double? amount,
    String? note,
    DateTime? date,
    TransactionType? type,
    String? splitId,
  }) {
    return Transaction(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      type: type ?? this.type,
      splitId: splitId ?? this.splitId,
    );
  }
}
