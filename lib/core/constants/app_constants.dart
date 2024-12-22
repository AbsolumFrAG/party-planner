class AppConstants {
  // App Info
  static const String appName = 'Party Planner';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Routing
  static const String initialRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String partyListRoute = '/parties';
  static const String partyDetailsRoute = '/party-details';
  static const String createPartyRoute = '/create-party';
  static const String editPartyRoute = '/edit-party';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userPreferencesKey = 'user_preferences';
  static const String themeKey = 'app_theme';
  static const String localeKey = 'app_locale';
  static const String onboardingCompletedKey = 'onboarding_completed';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const Duration cacheDuration = Duration(hours: 24);
  static const Duration sessionTimeout = Duration(hours: 12);
  static const Duration notificationDisplayDuration = Duration(seconds: 4);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int maxPartyTitleLength = 100;
  static const int maxPartyDescriptionLength = 500;
  static const int maxLocationLength = 200;
  static const int maxParticipants = 100;
  static const int minParticipants = 2;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double defaultElevation = 2.0;
  static const double defaultSpacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 24.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Date Formats
  static const String defaultDateFormat = 'dd/MM/yyyy';
  static const String defaultTimeFormat = 'HH:mm';
  static const String defaultDateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String shortDateFormat = 'd MMM';
  static const String shortMonthFormat = 'MMM yyyy';

  // Party Constants
  static const List<String> defaultCategories = [
    'Nourriture',
    'Boissons',
    'Alcool',
    'Desserts',
    'Snacks',
    'Ustensiles',
    'Décoration',
    'Autre'
  ];

  static const Map<String, String> itemUnits = {
    'unité': 'u.',
    'gramme': 'g',
    'kilogramme': 'kg',
    'litre': 'L',
    'millilitre': 'mL',
    'bouteille': 'bout.',
    'paquet': 'paq.',
    'personne': 'pers.'
  };

  // Error Messages
  static const String defaultErrorMessage =
      'Une erreur est survenue. Veuillez réessayer.';
  static const String networkErrorMessage =
      'Erreur de connexion. Vérifiez votre connexion Internet.';
  static const String sessionExpiredMessage =
      'Votre session a expiré. Veuillez vous reconnecter.';
  static const String invalidCredentialsMessage =
      'Email ou mot de passe incorrect.';
  static const String unauthorizedMessage =
      'Vous n\'avez pas les droits nécessaires pour effectuer cette action.';
  static const String partyFullMessage = 'Cette soirée est déjà complète.';
  static const String invalidAccessCodeMessage = 'Code d\'accès invalide.';

  // Success Messages
  static const String loginSuccessMessage = 'Connexion réussie !';
  static const String registrationSuccessMessage =
      'Inscription réussie ! Bienvenue.';
  static const String partyCreatedMessage = 'Soirée créée avec succès !';
  static const String itemAddedMessage = 'Item ajouté avec succès !';
  static const String itemAssignedMessage = 'Item assigné avec succès !';
  static const String profileUpdatedMessage = 'Profil mis à jour avec succès !';

  // Cache Keys
  static const String partiesCacheKey = 'cached_parties';
  static const String userProfileCacheKey = 'cached_user_profile';
  static const String categoriesCacheKey = 'cached_categories';

  const AppConstants._();
}
