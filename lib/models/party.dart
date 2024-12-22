import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:partyplanner/models/item.dart';

enum PartyStatus { planning, confirmed, ongoing, completed, cancelled }

class Party extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String? locationDetails;
  final GeoPoint? coordinates;
  final int maxParticipants;
  final PartyStatus status;
  final String organizerId;
  final String? organizerName;
  final List<String> coOrganizersIds;
  final List<String> participantsIds;
  final Map<String, String>? participantsNames;
  final List<Item> items;
  final Map<String, dynamic>? settings;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPrivate;
  final String? accessCode;
  final Map<String, dynamic>? metadata;

  const Party({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    this.locationDetails,
    this.coordinates,
    required this.maxParticipants,
    required this.status,
    required this.organizerId,
    this.organizerName,
    required this.coOrganizersIds,
    required this.participantsIds,
    this.participantsNames,
    required this.items,
    this.settings,
    required this.createdAt,
    this.updatedAt,
    required this.isPrivate,
    this.accessCode,
    this.metadata,
  });

  /// Créer une instance de Party à partir des données Firestore
  factory Party.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Party(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      locationDetails: data['locationDetails'],
      coordinates: data['coordinates'] as GeoPoint?,
      maxParticipants: data['maxParticipants'] ?? 0,
      status: PartyStatus.values.firstWhere(
        (e) => e.toString() == 'PartyStatus.${data['status']}',
        orElse: () => PartyStatus.planning,
      ),
      organizerId: data['organizerId'] ?? '',
      coOrganizersIds: List<String>.from(data['coOrganizersIds'] ?? []),
      participantsIds: List<String>.from(data['participantsIds'] ?? []),
      items: (data['items'] as List? ?? [])
          .map((item) => Item.fromFirestore(item))
          .toList(),
      settings: data['settings'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isPrivate: data['isPrivate'] ?? false,
      accessCode: data['accessCode'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'locationDetails': locationDetails,
      'coordinates': coordinates,
      'maxParticipants': maxParticipants,
      'status': status.toString().split('.').last,
      'organizerId': organizerId,
      'coOrganizersIds': coOrganizersIds,
      'participantsIds': participantsIds,
      'items': items.map((item) => item.toFirestore()).toList(),
      'settings': settings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isPrivate': isPrivate,
      'accessCode': accessCode,
      'metadata': metadata,
    };
  }

  /// Crée une copie de la soirée avec des champs modifiés
  Party copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? locationDetails,
    GeoPoint? coordinates,
    int? maxParticipants,
    PartyStatus? status,
    String? organizerId,
    String? organizerName,
    List<String>? coOrganizersIds,
    List<String>? participantsIds,
    Map<String, String>? participantsNames,
    List<Item>? items,
    Map<String, dynamic>? settings,
    DateTime? updatedAt,
    bool? isPrivate,
    String? accessCode,
    Map<String, dynamic>? metadata,
  }) {
    return Party(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      locationDetails: locationDetails ?? this.locationDetails,
      coordinates: coordinates ?? this.coordinates,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      status: status ?? this.status,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      coOrganizersIds: coOrganizersIds ?? this.coOrganizersIds,
      participantsIds: participantsIds ?? this.participantsIds,
      participantsNames: participantsNames ?? this.participantsNames,
      items: items ?? this.items,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrivate: isPrivate ?? this.isPrivate,
      accessCode: accessCode ?? this.accessCode,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isFull => participantsIds.length >= maxParticipants;
  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isOngoing => status == PartyStatus.ongoing;
  bool get isCompleted => status == PartyStatus.completed;
  bool get isCancelled => status == PartyStatus.cancelled;

  bool canJoin(String userId) {
    return !isFull &&
        !isCancelled &&
        !participantsIds.contains(userId) &&
        isUpcoming;
  }

  bool isOrganizer(String userId) {
    return organizerId == userId || coOrganizersIds.contains(userId);
  }

  bool canModify(String userId) {
    return isOrganizer(userId) && !isCompleted && !isCancelled;
  }

  List<Item> getItemsByUser(String userId) {
    return items.where((item) => item.assignedToUserId == userId).toList();
  }

  List<Item> getUnassignedItems() {
    return items.where((item) => item.assignedToUserId == null).toList();
  }

  List<Item> getItemsByCategory(ItemCategory category) {
    return items.where((item) => item.category == category).toList();
  }

  String getParticipantName(String participantId) {
    return participantsNames?[participantId] ?? 'Utilisateur inconnu';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        date,
        location,
        locationDetails,
        coordinates,
        maxParticipants,
        status,
        organizerId,
        coOrganizersIds,
        participantsIds,
        items,
        settings,
        createdAt,
        updatedAt,
        isPrivate,
        accessCode,
        metadata,
      ];

  @override
  String toString() => 'Party(id: $id, title: $title, date: $date)';
}
