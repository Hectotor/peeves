import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';

const String GEMINI_API_KEY = '';
const String GEMINI_API_URL =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({Key? key}) : super(key: key);

  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      "bot":
          "Bonjour, je suis votre assistant virtuel je m'appelle Peeves en quoi puis-je vous aider pour votre orientation professionnelle?",
      "isLoading": false
    }
  ];
  List<dynamic> _formations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFormations();
  }

  Future<void> _loadFormations() async {
    final String response =
        await rootBundle.loadString('assets/formations_parcoursup.json');
    final data = await json.decode(response);
    setState(() {
      _formations = data;
    });
  }

  Future<String> _askGemini(String question) async {
    try {
      String contextData = _formations
          .map((formation) =>
              "${formation['nom_etablissement']} - ${formation['nom_formation']} (Places disponibles: ${formation['places_disponibles']})")
          .join("\n");

      String promptWithContext = """
      Tu es un conseiller d'orientation professionnel spécialisé dans Parcoursup. 
      Ton rôle est d'aider les étudiants à trouver la formation qui leur correspond.
      
      Voici la base de données des formations disponibles :
      $contextData

      Directives de communication :
      1. Maintenir un ton professionnel et bienveillant
      2. Fournir des informations précises basées sur les données des formations
      3. Structurer les réponses de manière claire et concise
      4. Se concentrer uniquement sur les aspects académiques et professionnels
      5. Éviter le langage familier ou les expressions décontractées
      6. En cas de doute, recommander de consulter un conseiller d'orientation

      Question : $question

      Structure de réponse à suivre :
      1. Informations factuelles issues de la base de données
      2. Analyse et recommandations professionnelles
      3. Si nécessaire, suggestions d'alternatives pertinentes
      """;

      final response = await http.post(
        Uri.parse('$GEMINI_API_URL?key=$GEMINI_API_KEY'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": promptWithContext}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 2048,
          },
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['candidates'][0]['content']['parts'][0]['text'] ??
            "Désolé, je n'ai pas compris.";
      } else {
        return "Désolé, une erreur s'est produite.";
      }
    } catch (e) {
      return "Erreur de communication avec l'API: $e";
    }
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      final question = _controller.text;
      setState(() {
        _messages.add({"user": question});
        _messages.add({"bot": "...", "isLoading": true});
        _isLoading = true;
      });
      _controller.clear();

      // Utiliser directement Gemini pour toutes les questions
      final geminiResponse = await _askGemini(question);
      setState(() {
        _messages.removeLast();
        _messages.add({"bot": geminiResponse, "isLoading": false});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple,
                Colors.deepPurple.shade300,
              ],
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.android,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peeves',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Assistant virtuel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.containsKey("user");
                final isLoading = message["isLoading"] ?? false;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.deepPurple[100],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomLeft: isUser ? Radius.circular(10) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isUser)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child:
                                Icon(Icons.android, color: Colors.deepPurple),
                          ),
                        if (isLoading)
                          Container(
                            width: 50,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text("...")
                              ],
                            ),
                          )
                        else
                          Flexible(
                            child: Text(
                              isUser ? message["user"]! : message["bot"]!,
                              style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: _isLoading
                          ? 'Peeves réfléchit...'
                          : 'Posez votre question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
