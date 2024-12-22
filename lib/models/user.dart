import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<String> participatingParties;
  final List<String> organizedParties;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic>? preferences;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.participatingParties,
    required this.organizedParties,
    required this.createdAt,
    required this.lastLoginAt,
    this.preferences,
  });

  /// Crée une instance de User à partir des données Firebase
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Pour les timestamps, on utilise DateTime.now() si la valeur est null
    final Timestamp createdAtTimestamp =
        data['createdAt'] as Timestamp? ?? Timestamp.now();
    final Timestamp lastLoginAtTimestamp =
        data['lastLoginAt'] as Timestamp? ?? Timestamp.now();

    return User(
      id: doc.id,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      photoUrl: (data['photoUrl'] as String?) ?? '',
      participatingParties:
          List<String>.from(data['participatingParties'] ?? []),
      organizedParties: List<String>.from(data['organizedParties'] ?? []),
      createdAt: createdAtTimestamp.toDate(),
      lastLoginAt: lastLoginAtTimestamp.toDate(),
      preferences: (data['preferences'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'participatingParties': participatingParties,
      'organizedParties': organizedParties,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'preferences': preferences,
    };
  }

  /// Crée une copie de l'utilisateur avec des champs modifiés
  User copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    List<String>? participatingParties,
    List<String>? organizedParties,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      participatingParties: participatingParties ?? this.participatingParties,
      organizedParties: organizedParties ?? this.organizedParties,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
    );
  }

  /// Vérifie si l'utilisateur participe à une soirée
  bool isParticipatingIn(String partyId) {
    return participatingParties.contains(partyId);
  }

  /// Vérifie si l'utilisateur est l'organisateur d'une soirée
  bool isOrganizerOf(String partyId) {
    return organizedParties.contains(partyId);
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        participatingParties,
        organizedParties,
        createdAt,
        lastLoginAt,
        preferences,
      ];

  @override
  String toString() =>
      'User(id: $id, email: $email, displayName: $displayName)';
}
