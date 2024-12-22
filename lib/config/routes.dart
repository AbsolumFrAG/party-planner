import 'package:flutter/material.dart';

import '../views/screens/auth/login_screen.dart';
import '../views/screens/auth/register_screen.dart';
import '../views/screens/party/party_list_screen.dart';
import '../views/screens/party/party_details_screen.dart';
import '../views/screens/party/create_party_screen.dart';
import '../views/screens/items/items_list_screen.dart';
import '../views/screens/items/add_item_screen.dart';

class Routes {
  // Routes statiques pour éviter les erreurs de typo
  static const String login = '/login';
  static const String register = '/register';
  static const String parties = '/parties';
  static const String partyDetails = '/party-details';
  static const String createParty = '/create-party';
  static const String editParty = '/edit-party';
  static const String items = '/items';
  static const String addItem = '/add-item';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Map de toutes les routes de l'application
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      parties: (context) => const PartyListScreen(),
      partyDetails: (context) => const PartyDetailsScreen(),
      createParty: (context) => const CreatePartyScreen(),
      items: (context) => const ItemsListScreen(),
      addItem: (context) => const AddItemScreen(),
    };
  }

  // Gestionnaire pour les routes inconnues
  static Route<dynamic>? onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Page non trouvée',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La page "${settings.name}" n\'existe pas',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  parties,
                  (route) => false,
                ),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Middleware de navigation pour vérifier l'authentification
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeBuilder = getRoutes()[settings.name];

    if (routeBuilder != null) {
      // TODO: Ajouter ici la logique de vérification d'authentification si nécessaire
      return MaterialPageRoute(
        settings: settings,
        builder: routeBuilder,
      );
    }

    return onUnknownRoute(settings);
  }

  // Navigation avec arguments typés
  static Future<T?> navigateToPartyDetails<T>(
      BuildContext context, String partyId) {
    return Navigator.pushNamed(
      context,
      partyDetails,
      arguments: partyId,
    );
  }

  static Future<T?> navigateToItems<T>(BuildContext context, String partyId) {
    return Navigator.pushNamed(
      context,
      items,
      arguments: partyId,
    );
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      login,
      (route) => false,
    );
  }

  static void navigateToParties(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      parties,
      (route) => false,
    );
  }
}
