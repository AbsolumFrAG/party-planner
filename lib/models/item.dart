import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ItemCategory {
  food,
  drink,
  alcoholicDrink,
  dessert,
  snack,
  utensil,
  decoration,
  other
}

enum ItemStatus {
  needed, // L'item est requis mais personne ne s'est proposé
  assigned, // Quelqu'un s'est engagé à l'apporter
  brought, // L'item a été apporté à la soirée
  cancelled // L'item n'est plus nécessaire
}

class Item extends Equatable {
  final String id;
  final String name;
  final String? description;
  final ItemCategory category;
  final ItemStatus status;
  final int quantity;
  final String? unit;
  final String? assignedToUserId;
  final DateTime? assignedAt;
  final bool isRequired;
  final String createdByUserId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const Item({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.status,
    required this.quantity,
    this.unit,
    this.assignedToUserId,
    this.assignedAt,
    required this.isRequired,
    required this.createdByUserId,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Crée une instance de Item à partir des données Firestore
  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Item(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      category: ItemCategory.values.firstWhere(
        (e) => e.toString() == 'ItemCategory.${data['category']}',
        orElse: () => ItemCategory.other,
      ),
      status: ItemStatus.values.firstWhere(
        (e) => e.toString() == 'ItemStatus.${data['status']}',
        orElse: () => ItemStatus.needed,
      ),
      quantity: data['quantity'] ?? 1,
      unit: data['unit'],
      assignedToUserId: data['assignedToUserId'],
      assignedAt: data['assignedAt'] != null
          ? (data['assignedAt'] as Timestamp).toDate()
          : null,
      isRequired: data['isRequired'] ?? true,
      createdByUserId: data['createdByUserId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'],
    );
  }

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'status': status.toString().split('.').last,
      'quantity': quantity,
      'unit': unit,
      'assignedToUserId': assignedToUserId,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'isRequired': isRequired,
      'createdByUserId': createdByUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }

  /// Crée une copie de l'item avec des champs modifiés
  Item copyWith({
    String? name,
    String? description,
    ItemCategory? category,
    ItemStatus? status,
    int? quantity,
    String? unit,
    String? assignedToUserId,
    DateTime? assignedAt,
    bool? isRequired,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedAt: assignedAt ?? this.assignedAt,
      isRequired: isRequired ?? this.isRequired,
      createdByUserId: createdByUserId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Vérifie si l'item est assigné
  bool get isAssigned => assignedToUserId != null;

  /// Vérifie si l'item est apporté
  bool get isBrought => status == ItemStatus.brought;

  /// Vérifie si l'item est assigné à un utilisateur spécifique
  bool isAssignedTo(String userId) => assignedToUserId == userId;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        status,
        quantity,
        unit,
        assignedToUserId,
        assignedAt,
        isRequired,
        createdByUserId,
        createdAt,
        updatedAt,
        metadata,
      ];

  @override
  String toString() => 'Item(id: $id, name: $name, status: $status)';
}
