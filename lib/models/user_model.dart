class User {
  final int? id;
  final String nom;
  final String prenom;
  final String email;
  final String? numtel;
  final bool isAdmin; // <-- ADD THIS
  final String? createdAt;

  User({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.numtel,
    this.isAdmin = false, // <-- ADD THIS DEFAULT VALUE
    this.createdAt,
  });

  /// ✅ Convertit une ligne de la base de données SQLite en objet User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      email: map['email'],
      numtel: map['numtel'],
      isAdmin: map['isAdmin'] == 1, // <-- ADD THIS LOGIC TO CONVERT FROM DB
      createdAt: map['created_at'],
    );
  }

  /// ✅ Convertit un objet User en Map pour insertion dans SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'numtel': numtel,
      'isAdmin': isAdmin ? 1 : 0, // ✅ bool → int pour SQLite
      'created_at': createdAt,
    };
  }

  /// ✅ Getter utile pour l’affichage du nom complet
  String get fullName => '$prenom $nom';

  /// ✅ Crée une copie modifiée d’un utilisateur
  User copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? email,
    String? numtel,
    bool? isAdmin,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      numtel: numtel ?? this.numtel,
      isAdmin: isAdmin ?? this.isAdmin, // ✅ conserve ou modifie isAdmin
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
