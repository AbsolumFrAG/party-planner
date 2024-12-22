import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../constants/firebase_constants.dart';
import '../../models/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    required SharedPreferences prefs,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _prefs = prefs;

  // Stream de l'état de l'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  // Inscription avec email et mot de passe
  Future<app_user.User> signUp({
    required String email,
    required String password,
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      // Création du compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Échec de la création du compte');
      }

      // Mise à jour du profil
      await userCredential.user!.updateDisplayName(displayName);
      if (photoUrl != null) {
        await userCredential.user!.updatePhotoURL(photoUrl);
      }

      // Création du document utilisateur dans Firestore
      final userData = app_user.User(
        id: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl ?? '', // Valeur par défaut si null
        participatingParties: const [],
        organizedParties: const [],
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        preferences: const {}, // Valeur par défaut pour preferences
      );

      await FirebaseConstants.getUserRef(userCredential.user!.uid)
          .set(userData.toFirestore());

      // Sauvegarde du token
      await _saveUserToken((await userCredential.user!.getIdToken())!);

      return userData;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Connexion avec email et mot de passe
  Future<app_user.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Échec de la connexion');
      }

      final user = userCredential.user!;

      // Mise à jour de la dernière connexion
      await FirebaseConstants.getUserRef(user.uid)
          .update({'lastLoginAt': FieldValue.serverTimestamp()});

      // Récupération des données utilisateur
      final userData = await FirebaseConstants.getUserRef(user.uid).get();

      if (!userData.exists) {
        // Si les données n'existent pas dans Firestore, on les crée
        final newUserData = app_user.User(
          id: user.uid,
          email: email,
          displayName: user.displayName ?? email.split('@')[0],
          photoUrl: user.photoURL ?? '',
          participatingParties: const [],
          organizedParties: const [],
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          preferences: const {},
        );
        await FirebaseConstants.getUserRef(user.uid)
            .set(newUserData.toFirestore());

        // Sauvegarde du token
        await _saveUserToken((await user.getIdToken())!);

        return newUserData;
      }

      // Sauvegarde du token
      await _saveUserToken((await user.getIdToken())!);

      return app_user.User.fromFirestore(userData);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
    await _prefs.remove(AppConstants.userTokenKey);
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Mise à jour du profil
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      if (displayName != null) {
        await currentUser!.updateDisplayName(displayName);
        await FirebaseConstants.getUserRef(currentUser!.uid)
            .update({'displayName': displayName});
      }

      if (photoUrl != null) {
        await currentUser!.updatePhotoURL(photoUrl);
        await FirebaseConstants.getUserRef(currentUser!.uid)
            .update({'photoUrl': photoUrl});
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Mise à jour du mot de passe
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (currentUser == null || currentUser!.email == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Revérification de l'authentification
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );
      await currentUser!.reauthenticateWithCredential(credential);

      // Mise à jour du mot de passe
      await currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Suppression du compte
  Future<void> deleteAccount(String password) async {
    try {
      if (currentUser == null || currentUser!.email == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Revérification de l'authentification
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
      await currentUser!.reauthenticateWithCredential(credential);

      // Suppression des données Firestore
      await FirebaseConstants.getUserRef(currentUser!.uid).delete();

      // Suppression du compte Auth
      await currentUser!.delete();

      // Suppression du token local
      await _prefs.remove(AppConstants.userTokenKey);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sauvegarde du token utilisateur
  Future<void> _saveUserToken(String token) async {
    await _prefs.setString(AppConstants.userTokenKey, token);
  }

  // Gestion des erreurs Firebase Auth
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Aucun utilisateur trouvé avec cet email');
      case 'wrong-password':
        return Exception('Mot de passe incorrect');
      case 'email-already-in-use':
        return Exception('Un compte existe déjà avec cet email');
      case 'weak-password':
        return Exception('Le mot de passe est trop faible');
      case 'invalid-email':
        return Exception('Email invalide');
      case 'operation-not-allowed':
        return Exception('Opération non autorisée');
      case 'user-disabled':
        return Exception('Ce compte a été désactivé');
      case 'too-many-requests':
        return Exception('Trop de tentatives, veuillez réessayer plus tard');
      default:
        return Exception(e.message ?? 'Une erreur est survenue');
    }
  }
}
