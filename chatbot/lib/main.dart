import 'package:flutter/material.dart';
import 'splash.dart'; // Importer l'écran de splash
import 'chatbot.dart'; // Importer l'écran du chatbot

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key); // Modification ici

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peeves',
      debugShowCheckedModeBanner:
          false, // Ajout de cette ligne pour cacher le badge debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:
          const SplashScreen(), // Utiliser l'écran de splash comme écran d'accueil
      routes: {
        '/chatbot': (context) =>
            const ChatBotScreen(), // Définir la route pour le chatbot
      },
    );
  }
}
