import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseConstants {
  // Collection Names
  static const String usersCollection = 'users';
  static const String partiesCollection = 'parties';
  static const String itemsCollection = 'items';
  static const String notificationsCollection = 'notifications';
  static const String messagesCollection = 'messages';
  static const String feedbackCollection = 'feedback';
  static const String analyticsCollection = 'analytics';

  // Subcollection Names
  static const String partyItemsSubcollection = 'items';
  static const String partyMessagesSubcollection = 'messages';
  static const String partyParticipantsSubcollection = 'participants';
  static const String userNotificationsSubcollection = 'notifications';
  static const String userPartiesSubcollection = 'parties';

  // Storage Paths
  static const String userProfileImagesPath = 'profile_images';
  static const String partyImagesPath = 'party_images';
  static const String itemImagesPath = 'item_images';
  static const String messageAttachmentsPath = 'message_attachments';

  // Collection References
  static final CollectionReference<Map<String, dynamic>> usersRef =
      FirebaseFirestore.instance.collection(usersCollection);

  static final CollectionReference<Map<String, dynamic>> partiesRef =
      FirebaseFirestore.instance.collection(partiesCollection);

  static final CollectionReference<Map<String, dynamic>> itemsRef =
      FirebaseFirestore.instance.collection(itemsCollection);

  static final CollectionReference<Map<String, dynamic>> notificationsRef =
      FirebaseFirestore.instance.collection(notificationsCollection);

  static final CollectionReference<Map<String, dynamic>> messagesRef =
      FirebaseFirestore.instance.collection(messagesCollection);

  static final CollectionReference<Map<String, dynamic>> feedbackRef =
      FirebaseFirestore.instance.collection(feedbackCollection);

  static final CollectionReference<Map<String, dynamic>> analyticsRef =
      FirebaseFirestore.instance.collection(analyticsCollection);

  // Storage References
  static final Reference userProfileImagesRef =
      FirebaseStorage.instance.ref().child(userProfileImagesPath);

  static final Reference partyImagesRef =
      FirebaseStorage.instance.ref().child(partyImagesPath);

  static final Reference itemImagesRef =
      FirebaseStorage.instance.ref().child(itemImagesPath);

  static final Reference messageAttachmentsRef =
      FirebaseStorage.instance.ref().child(messageAttachmentsPath);

  // Helper Methods
  static DocumentReference<Map<String, dynamic>> getUserRef(String userId) {
    return usersRef.doc(userId);
  }

  static DocumentReference<Map<String, dynamic>> getPartyRef(String partyId) {
    return partiesRef.doc(partyId);
  }

  static CollectionReference<Map<String, dynamic>> getPartyItemsRef(
      String partyId) {
    return partiesRef.doc(partyId).collection(partyItemsSubcollection);
  }

  static CollectionReference<Map<String, dynamic>> getPartyMessagesRef(
      String partyId) {
    return partiesRef.doc(partyId).collection(partyMessagesSubcollection);
  }

  static CollectionReference<Map<String, dynamic>> getPartyParticipantsRef(
      String partyId) {
    return partiesRef.doc(partyId).collection(partyParticipantsSubcollection);
  }

  static CollectionReference<Map<String, dynamic>> getUserNotificationsRef(
      String userId) {
    return usersRef.doc(userId).collection(userNotificationsSubcollection);
  }

  static CollectionReference<Map<String, dynamic>> getUserPartiesRef(
      String userId) {
    return usersRef.doc(userId).collection(userPartiesSubcollection);
  }

  static Reference getUserProfileImageRef(String userId) {
    return userProfileImagesRef.child('$userId.jpg');
  }

  static Reference getPartyImageRef(String partyId) {
    return partyImagesRef.child('$partyId.jpg');
  }

  static Reference getItemImageRef(String itemId) {
    return itemImagesRef.child('$itemId.jpg');
  }

  static Reference getMessageAttachmentRef(String messageId, String fileName) {
    return messageAttachmentsRef.child(messageId).child(fileName);
  }

  // Indexing and Query Constants
  static const int maxQueryLimit = 100;
  static const Duration cacheTimeout = Duration(minutes: 30);

  // Batch Processing Constants
  static const int maxBatchOperations = 500;
  static const int maxTransactionOperations = 100;

  const FirebaseConstants._();
}
