class Payment {
  int? id;
  int userId;
  int packId;
  double amount;
  int date; // millis since epoch
  String status;

  Payment({
    this.id,
    required this.userId,
    required this.packId,
    required this.amount,
    required this.date,
    this.status = 'paid',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'pack_id': packId,
    'amount': amount,
    'date': date,
    'status': status,
  };

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
    id: m['id'] as int?,
    userId: m['user_id'] as int,
    packId: m['pack_id'] as int,
    amount: (m['amount'] as num).toDouble(),
    date: m['date'] as int,
    status: m['status'] as String? ?? 'paid',
  );
}
