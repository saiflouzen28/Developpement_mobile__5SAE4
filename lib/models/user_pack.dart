class UserPack {
  int? id;
  int userId;
  int packId;
  int startDate;
  int endDate;

  UserPack({
    this.id,
    required this.userId,
    required this.packId,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'pack_id': packId,
    'start_date': startDate,
    'end_date': endDate,
  };

  factory UserPack.fromMap(Map<String, dynamic> m) => UserPack(
    id: m['id'] as int?,
    userId: m['user_id'] as int,
    packId: m['pack_id'] as int,
    startDate: m['start_date'] as int,
    endDate: m['end_date'] as int,
  );
}
