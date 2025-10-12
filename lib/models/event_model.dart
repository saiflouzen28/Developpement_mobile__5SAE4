class Event {
  final int? id;
  final String title;
  final String description;
  final String? imageUrl;
  final String location;
  final double? latitude;
  final double? longitude;
  final String eventDate;
  final String eventTime;
  final int maxParticipants;
  final int currentParticipants;
  final String category;
  final int? createdBy;
  final String? createdAt;

  Event({
    this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.location,
    this.latitude,
    this.longitude,
    required this.eventDate,
    required this.eventTime,
    required this.maxParticipants,
    this.currentParticipants = 0,
    required this.category,
    this.createdBy,
    this.createdAt,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['image_url'],
      location: map['location'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      eventDate: map['event_date'],
      eventTime: map['event_time'],
      maxParticipants: map['max_participants'],
      currentParticipants: map['current_participants'] ?? 0,
      category: map['category'],
      createdBy: map['created_by'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'event_date': eventDate,
      'event_time': eventTime,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'category': category,
      'created_by': createdBy,
      'created_at': createdAt,
    };
  }

  int get availableSeats => maxParticipants - currentParticipants;
  
  bool get isFull => currentParticipants >= maxParticipants;
  
  bool get hasAvailableSeats => availableSeats > 0;

  String get formattedDate {
    final date = DateTime.parse(eventDate);
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedTime {
    return eventTime;
  }

  String get eventDateTime {
    return '$formattedDate at $formattedTime';
  }

  double? get progress => maxParticipants > 0 ? currentParticipants / maxParticipants : 0;

  Event copyWith({
    int? id,
    String? title,
    String? description,
    String? imageUrl,
    String? location,
    double? latitude,
    double? longitude,
    String? eventDate,
    String? eventTime,
    int? maxParticipants,
    int? currentParticipants,
    String? category,
    int? createdBy,
    String? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      category: category ?? this.category,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}