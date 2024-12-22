import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firebase_constants.dart';
import '../../models/party.dart';
import '../../models/item.dart';

class FirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Getter pour l'utilisateur courant
  User? get currentUser => _auth.currentUser;

  // Obtenir les soirées de l'utilisateur courant
  Stream<List<Party>> getUserParties() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection(FirebaseConstants.partiesCollection)
        .where('participantsIds', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final parties = <Party>[];

      for (var doc in snapshot.docs) {
        final party = Party.fromFirestore(doc);
        // Récupérer les informations de l'organisateur
        final organizerDoc = await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(party.organizerId)
            .get();

        // Récupérer les informations des participants
        final participantsData = await Future.wait(
          party.participantsIds.map((participantId) => _firestore
              .collection(FirebaseConstants.usersCollection)
              .doc(participantId)
              .get()),
        );

        // Créer un map des noms des participants avec le bon type
        final participantsNames = Map<String, String>.fromEntries(
          participantsData.where((doc) => doc.exists).map((doc) => MapEntry(
              doc.id,
              (doc.data()?['displayName'] as String?) ??
                  'Utilisateur inconnu')),
        );

        if (organizerDoc.exists) {
          final organizerData = organizerDoc.data();
          // Mettre à jour le party avec le nom de l'organisateur et les noms des participants
          parties.add(party.copyWith(
            organizerName: organizerData?['displayName'] as String? ??
                'Utilisateur inconnu',
            participantsNames: participantsNames,
          ));
        } else {
          parties.add(party.copyWith(participantsNames: participantsNames));
        }
      }

      // Tri côté client
      parties.sort((a, b) => b.date.compareTo(a.date));
      return parties;
    });
  }

  // Obtenir les soirées organisées par l'utilisateur
  Stream<List<Party>> getOrganizedParties() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection(FirebaseConstants.partiesCollection)
        .where('organizerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final parties =
          snapshot.docs.map((doc) => Party.fromFirestore(doc)).toList();
      // Tri côté client
      parties.sort((a, b) => b.date.compareTo(a.date));
      return parties;
    });
  }

  // Créer une nouvelle soirée
  Future<String> createParty(Party party) async {
    final docRef = await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .add(party.toFirestore());

    // Mettre à jour les soirées organisées de l'utilisateur
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(party.organizerId)
        .update({
      'organizedParties': FieldValue.arrayUnion([docRef.id])
    });

    return docRef.id;
  }

  // Mettre à jour une soirée
  Future<void> updateParty(String partyId, Party party) async {
    await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .doc(partyId)
        .update(party.toFirestore());
  }

  // Supprimer une soirée
  Future<void> deleteParty(String partyId) async {
    final partyDoc = await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .doc(partyId)
        .get();

    if (!partyDoc.exists) return;

    final party = Party.fromFirestore(partyDoc);

    // Supprimer la référence dans organizedParties de l'organisateur
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(party.organizerId)
        .update({
      'organizedParties': FieldValue.arrayRemove([partyId])
    });

    // Supprimer les références dans participatingParties des participants
    for (final participantId in party.participantsIds) {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(participantId)
          .update({
        'participatingParties': FieldValue.arrayRemove([partyId])
      });
    }

    // Supprimer la soirée
    await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .doc(partyId)
        .delete();
  }

  // Rejoindre une soirée
  Future<void> joinParty(String partyId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté');

    // Ajouter l'utilisateur aux participants de la soirée
    await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .doc(partyId)
        .update({
      'participantsIds': FieldValue.arrayUnion([userId])
    });

    // Ajouter la soirée aux soirées participées de l'utilisateur
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .update({
      'participatingParties': FieldValue.arrayUnion([partyId])
    });
  }

  // Quitter une soirée
  Future<void> leaveParty(String partyId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté');

    // Retirer l'utilisateur des participants de la soirée
    await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .doc(partyId)
        .update({
      'participantsIds': FieldValue.arrayRemove([userId])
    });

    // Retirer la soirée des soirées participées de l'utilisateur
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .update({
      'participatingParties': FieldValue.arrayRemove([partyId])
    });
  }

  // Ajouter un item à une soirée
  Future<void> addItemToParty(String partyId, Item item) async {
    await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .doc(partyId)
        .update({
      'items': FieldValue.arrayUnion([item.toFirestore()])
    });
  }

  // Mettre à jour un item
  Future<void> updateItem(String partyId, Item oldItem, Item newItem) async {
    await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .doc(partyId)
        .update({
      'items': FieldValue.arrayRemove([oldItem.toFirestore()]),
    });

    await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .doc(partyId)
        .update({
      'items': FieldValue.arrayUnion([newItem.toFirestore()]),
    });
  }

  // Supprimer un item
  Future<void> deleteItem(String partyId, Item item) async {
    await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .doc(partyId)
        .update({
      'items': FieldValue.arrayRemove([item.toFirestore()])
    });
  }

  // Assigner un item à un utilisateur
  Future<void> assignItem(String partyId, String itemId, String userId) async {
    final partyDoc = await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .doc(partyId)
        .get();

    if (!partyDoc.exists) throw Exception('Soirée introuvable');

    final party = Party.fromFirestore(partyDoc);
    final item = party.items.firstWhere((i) => i.id == itemId);
    final updatedItem = item.copyWith(
      assignedToUserId: userId,
      assignedAt: DateTime.now(),
      status: ItemStatus.assigned,
    );

    await updateItem(partyId, item, updatedItem);
  }

  // Désassigner un item
  Future<void> unassignItem(String partyId, String itemId) async {
    final partyDoc = await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .doc(partyId)
        .get();

    if (!partyDoc.exists) throw Exception('Soirée introuvable');

    final party = Party.fromFirestore(partyDoc);
    final item = party.items.firstWhere((i) => i.id == itemId);
    final updatedItem = item.copyWith(
      assignedToUserId: null,
      assignedAt: null,
      status: ItemStatus.needed,
    );

    await updateItem(partyId, item, updatedItem);
  }

  // Marquer un item comme apporté
  Future<void> markItemAsBrought(String partyId, String itemId) async {
    final partyDoc = await _firestore
        .collection(FirebaseConstants.partiesCollection)
        .doc(partyId)
        .get();

    if (!partyDoc.exists) throw Exception('Soirée introuvable');

    final party = Party.fromFirestore(partyDoc);
    final item = party.items.firstWhere((i) => i.id == itemId);
    final updatedItem = item.copyWith(status: ItemStatus.brought);

    await updateItem(partyId, item, updatedItem);
  }
}
