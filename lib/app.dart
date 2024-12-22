import 'package:flutter/material.dart';
import 'package:partyplanner/config/routes.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/auth_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/party_viewmodel.dart';
import 'viewmodels/items_viewmodel.dart';

import 'views/screens/auth/login_screen.dart';
import 'views/screens/party/party_list_screen.dart';

class PartyPlannerApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const PartyPlannerApp({
    super.key,
    required this.sharedPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(
          create: (_) => AuthService(prefs: sharedPreferences),
        ),
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),

        // ViewModels
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authService: context.read<AuthService>(),
            notificationService: context.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProvider<PartyViewModel>(
          create: (context) => PartyViewModel(
            firebaseService: context.read<FirebaseService>(),
            notificationService: context.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProvider<ItemsViewModel>(
          create: (context) => ItemsViewModel(
            firebaseService: context.read<FirebaseService>(),
            notificationService: context.read<NotificationService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Party Planner',
        theme: _buildTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', ''),
        ],
        home: const AuthenticationWrapper(),
        routes: Routes.getRoutes(),
        onGenerateRoute: Routes.onGenerateRoute,
        onUnknownRoute: Routes.onUnknownRoute,
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      useMaterial3: true,
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          return const PartyListScreen(); // Point d'entrée après authentification
        }
        
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}