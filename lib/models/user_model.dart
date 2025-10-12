class User {
  final int? id;
  final String nom;
  final String prenom;
  final String email;
  final String? numtel;
  final String? createdAt;

  User({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.numtel,
    this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      email: map['email'],
      numtel: map['numtel'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'numtel': numtel,
      'created_at': createdAt,
    };
  }

  String get fullName => '$prenom $nom';

  User copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? email,
    String? numtel,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      numtel: numtel ?? this.numtel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}