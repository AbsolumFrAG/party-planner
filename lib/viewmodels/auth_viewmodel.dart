import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as app_user;
import '../core/services/auth_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/validators.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error
}

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final NotificationService _notificationService;

  AuthStatus _status = AuthStatus.initial;
  app_user.User? _user;
  String? _error;
  bool _isLoading = false;

  AuthViewModel({
    required AuthService authService,
    required NotificationService notificationService,
  })  : _authService = authService,
        _notificationService = notificationService {
    // Écouter les changements d'état d'authentification
    _authService.authStateChanges.listen(_handleAuthStateChanged);
  }

  // Getters
  AuthStatus get status => _status;
  app_user.User? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Gestion de l'état d'authentification
  void _handleAuthStateChanged(User? firebaseUser) {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      _status = AuthStatus.authenticated;
      // Mettre à jour le token FCM après l'authentification
      // Note: on utilise unawaited car on ne peut pas await dans un listener synchrone
      _notificationService.updateFcmToken().then((_) => notifyListeners());
    }
    notifyListeners();
  }

  // Inscription
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    String? photoUrl,
  }) async {
    // Validation
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      _error = emailError;
      notifyListeners();
      return false;
    }

    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) {
      _error = passwordError;
      notifyListeners();
      return false;
    }

    try {
      _setLoading(true);
      _status = AuthStatus.authenticating;
      notifyListeners();

      _user = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        photoUrl: photoUrl,
      );

      _status = AuthStatus.authenticated;
      _error = null;
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Connexion
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    // Validation
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      _error = emailError;
      notifyListeners();
      return false;
    }

    try {
      _setLoading(true);
      _status = AuthStatus.authenticating;
      notifyListeners();

      _user = await _authService.signIn(
        email: email,
        password: password,
      );

      _status = AuthStatus.authenticated;
      _error = null;
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      _setLoading(true);

      // Supprimer le token FCM avant la déconnexion
      await _notificationService.deleteFcmToken();
      await _authService.signOut();

      _user = null;
      _status = AuthStatus.unauthenticated;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Réinitialisation du mot de passe
  Future<bool> resetPassword(String email) async {
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      _error = emailError;
      notifyListeners();
      return false;
    }

    try {
      _setLoading(true);
      await _authService.resetPassword(email);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mise à jour du profil
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      _setLoading(true);
      await _authService.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mise à jour du mot de passe
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final passwordError = Validators.validatePassword(newPassword);
    if (passwordError != null) {
      _error = passwordError;
      notifyListeners();
      return false;
    }

    try {
      _setLoading(true);
      await _authService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Suppression du compte
  Future<bool> deleteAccount(String password) async {
    try {
      _setLoading(true);
      await _notificationService.deleteFcmToken();
      await _authService.deleteAccount(password);
      _user = null;
      _status = AuthStatus.unauthenticated;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Utilitaire pour gérer l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Réinitialiser l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
