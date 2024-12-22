import 'package:partyplanner/core/constants/app_constants.dart';

class Validators {
  // Email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }

    return null;
  }

  // Mot de passe
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Le mot de passe doit contenir au moins ${AppConstants.minPasswordLength} caractères';
    }

    if (value.length > AppConstants.maxPasswordLength) {
      return 'Le mot de passe ne peut pas dépasser ${AppConstants.maxPasswordLength} caractères';
    }

    final hasUpperCase = value.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = value.contains(RegExp(r'[a-z]'));
    final hasNumbers = value.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters =
        value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUpperCase ||
        !hasLowerCase ||
        !hasNumbers ||
        !hasSpecialCharacters) {
      return 'Le mot de passe doit contenir des majuscules, minuscules, chiffres et caractères spéciaux';
    }

    return null;
  }

  // Confirmation de mot de passe
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'La confirmation du mot de passe est requise';
    }

    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }

    return null;
  }

  // Nom d'utilisateur
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom d\'utilisateur est requis';
    }

    if (value.length < AppConstants.minUsernameLength) {
      return 'Le nom d\'utilisateur doit contenir au moins ${AppConstants.minUsernameLength} caractères';
    }

    if (value.length > AppConstants.maxUsernameLength) {
      return 'Le nom d\'utilisateur ne peut pas dépasser ${AppConstants.maxUsernameLength} caractères';
    }

    final validCharacters = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!validCharacters.hasMatch(value)) {
      return 'Le nom d\'utilisateur ne peut contenir que des lettres, chiffres, points et underscores';
    }

    return null;
  }

  // Titre de soirée
  static String? validatePartyTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le titre est requis';
    }

    if (value.length > AppConstants.maxPartyTitleLength) {
      return 'Le titre ne peut pas dépasser ${AppConstants.maxPartyTitleLength} caractères';
    }

    return null;
  }

  // Description de soirée
  static String? validatePartyDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'La description est requise';
    }

    if (value.length > AppConstants.maxPartyDescriptionLength) {
      return 'La description ne peut pas dépasser ${AppConstants.maxPartyDescriptionLength} caractères';
    }

    return null;
  }

  // Localisation
  static String? validateLocation(String? value) {
    if (value == null || value.isEmpty) {
      return 'La localisation est requise';
    }

    if (value.length > AppConstants.maxLocationLength) {
      return 'La localisation ne peut pas dépasser ${AppConstants.maxLocationLength} caractères';
    }

    return null;
  }

  // Date de soirée
  static String? validatePartyDate(DateTime? value) {
    if (value == null) {
      return 'La date est requise';
    }

    if (value.isBefore(DateTime.now())) {
      return 'La date ne peut pas être dans le passé';
    }

    return null;
  }

  // Nombre de participants
  static String? validateParticipants(int? value) {
    if (value == null) {
      return 'Le nombre de participants est requis';
    }

    if (value < AppConstants.minParticipants) {
      return 'Le nombre minimum de participants est ${AppConstants.minParticipants}';
    }

    if (value > AppConstants.maxParticipants) {
      return 'Le nombre maximum de participants est ${AppConstants.maxParticipants}';
    }

    return null;
  }

  // Quantité d'items
  static String? validateItemQuantity(int? value) {
    if (value == null) {
      return 'La quantité est requise';
    }

    if (value <= 0) {
      return 'La quantité doit être supérieure à 0';
    }

    return null;
  }

  // Code d'accès
  static String? validateAccessCode(String? value, {bool isRequired = true}) {
    if (!isRequired && (value == null || value.isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.isEmpty)) {
      return 'Le code d\'accès est requis';
    }

    final validCharacters = RegExp(r'^[a-zA-Z0-9]{6,12}$');
    if (!validCharacters.hasMatch(value!)) {
      return 'Le code d\'accès doit contenir entre 6 et 12 caractères alphanumériques';
    }

    return null;
  }

  // URL
  static String? validateUrl(String? value, {bool isRequired = false}) {
    if (!isRequired && (value == null || value.isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.isEmpty)) {
      return 'L\'URL est requise';
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );

    if (!urlRegex.hasMatch(value!)) {
      return 'URL invalide';
    }

    return null;
  }

  // Numéro de téléphone
  static String? validatePhoneNumber(String? value, {bool isRequired = false}) {
    if (!isRequired && (value == null || value.isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.isEmpty)) {
      return 'Le numéro de téléphone est requis';
    }

    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value!)) {
      return 'Numéro de téléphone invalide';
    }

    return null;
  }

  const Validators._();
}
