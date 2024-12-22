import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/firebase_constants.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications;

  // Canal de notification par défaut pour Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifications importantes',
    description: 'Ce canal est utilisé pour les notifications importantes',
    importance: Importance.max,
    enableVibration: true,
  );

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  // Initialisation du service
  Future<void> initialize() async {
    // Demande des permissions de notification
    await requestPermissions();

    // Configuration des notifications locales
    await _initializeLocalNotifications();

    // Configuration des handlers de messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Vérification des notifications initiales
    await _checkInitialMessage();
  }

  // Demande des permissions de notification
  Future<bool> requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Initialisation des notifications locales
  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Création du canal Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  // Gestion des messages en premier plan
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Afficher une notification locale
    await showLocalNotification(
      title: message.notification?.title ?? 'Nouvelle notification',
      body: message.notification?.body ?? '',
      payload: message.data['route'],
    );

    // Sauvegarder la notification dans Firestore
    await _saveNotificationToFirestore(message);
  }

  // Gestion des messages en arrière-plan
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Cette méthode doit être static et top-level
    // Limiter le traitement pour éviter les problèmes de performance
    print('Handling background message: ${message.messageId}');
  }

  // Gestion des messages ouverts depuis les notifications
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    // Navigation selon la route spécifiée
    final route = message.data['route'];
    if (route != null) {
      // TODO: Implémenter la navigation
      print('Navigate to: $route');
    }
  }

  // Vérification des messages initiaux
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      await _handleMessageOpenedApp(initialMessage);
    }
  }

  // Gestion du tap sur une notification locale
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // TODO: Implémenter la navigation
      print('Navigate to: ${response.payload}');
    }
  }

  // Affichage d'une notification locale
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // Sauvegarde d'une notification dans Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await FirebaseConstants.getUserNotificationsRef(userId).add({
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // Envoi d'une notification pour une soirée
  Future<void> sendPartyNotification({
    required String partyId,
    required String title,
    required String body,
    required List<String> recipientIds,
  }) async {
    for (final userId in recipientIds) {
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) continue;

      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) continue;

      // Appel à Cloud Functions pour envoyer la notification
      // Note: Nécessite une Cloud Function configurée
      await _firestore.collection('notifications').add({
        'token': fcmToken,
        'title': title,
        'body': body,
        'data': {
          'route': '/party/$partyId',
          'partyId': partyId,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Mise à jour du token FCM
  Future<void> updateFcmToken() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  // Suppression du token FCM
  Future<void> deleteFcmToken() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .update({'fcmToken': FieldValue.delete()});

    await _messaging.deleteToken();
  }

  // Marquer une notification comme lue
  Future<void> markNotificationAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await FirebaseConstants.getUserNotificationsRef(userId)
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await FirebaseConstants.getUserNotificationsRef(userId)
        .doc(notificationId)
        .delete();
  }
}
