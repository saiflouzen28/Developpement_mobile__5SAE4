// lib/models/ticket_model.dart
class Ticket {
  final int? id;
  final int userId;
  final int eventId;
  final String ticketCode;
  final DateTime registeredAt;
  final bool isScanned;
  final DateTime? scannedAt;

  Ticket({
    this.id,
    required this.userId,
    required this.eventId,
    required this.ticketCode,
    required this.registeredAt,
    this.isScanned = false,
    this.scannedAt,
  });

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'],
      userId: map['user_id'],
      eventId: map['event_id'],
      ticketCode: map['ticket_code'],
      registeredAt: DateTime.parse(map['registered_at']),
      isScanned: map['is_scanned'] == 1,
      scannedAt: map['scanned_at'] != null ? DateTime.parse(map['scanned_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'ticket_code': ticketCode,
      'registered_at': registeredAt.toIso8601String(),
      'is_scanned': isScanned ? 1 : 0,
      'scanned_at': scannedAt?.toIso8601String(),
    };
  }
}
