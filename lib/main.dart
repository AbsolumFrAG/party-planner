import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  // S'assurer que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase avec les options générées
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialiser SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Configurer les erreurs non capturées
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // Lancer l'application
  runApp(PartyPlannerApp(sharedPreferences: prefs));
}
