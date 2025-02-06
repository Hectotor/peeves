import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';

const String GEMINI_API_KEY = 'AIzaSyBeiIggxVotCsQJCk1TFmP_ugWVRr57QGY';
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
          "En quoi puis-je vous aider dans votre orientation professionnelle?",
      "isLoading": false
    }
  ];
  bool _isLoading = false;
  List<Map<String, dynamic>> _formations = [];

  @override
  void initState() {
    super.initState();
    _loadFormations();
  }

  Future<void> _loadFormations() async {
    try {
      final String response =
          await rootBundle.loadString('assets/formations_parcoursup.json');
      final data = await json.decode(response);
      setState(() {
        _formations = List<Map<String, dynamic>>.from(data);
      });
      print('Données chargées avec succès');
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    }
  }

  Future<String> _askGemini(String question) async {
    try {
      // Rechercher les formations pertinentes dans le fichier JSON
      String contextData = _formations
          .map((formation) =>
              "${formation['nom_etablissement']} - ${formation['nom_formation']}")
          .join("\n");

      String promptWithContext = """
      Tu es Peeves, un conseiller d'orientation moderne et dynamique spécialisé dans Parcoursup.
      Ne commence jamais tes réponses par des salutations ou formules de politesse.
      Réponds de manière directe et naturelle comme dans une conversation fluide en cours.
      Évite les "Bonjour", "Salut", "Je suis ravi", etc.

      Stratégie de recherche et présentation :
      1. D'abord, cherche par type de formation demandée :
         - Identifie le domaine d'études souhaité
         - Trouve toutes les formations correspondantes
         - Liste les 2-3 meilleures correspondances
      2. Ensuite seulement, prends en compte la localisation :
         - Parmi les formations trouvées, mets en avant celles dans la ville demandée
         - Si aucune formation dans la ville, suggère la plus proche

      Format de présentation des résultats :
      1. Directement lister les formations en [domaine] trouvées
      2. Pour chaque formation :
         • Nom de la formation
         • Établissement et ville
         • Points clés
         • Conseil d'admission

      Règles essentielles :
      1. Le type de formation est le critère principal
      2. La localisation est un critère secondaire
      3. Reste concis et direct
      4. Si besoin de précision, pose UNE seule question ciblée
      5. Pas de formules de politesse ni d'introduction

      Je connais ces formations (à filtrer selon les critères ci-dessus) :
      $contextData

      Question : $question
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
      backgroundColor: const Color(0xFFF2F2F7), // Fond gris très clair iOS
      appBar: AppBar(
        backgroundColor: Color(0xFFf5fbff),
        elevation: 0.5,
        title: const Text(
          'Peeves - Votre assistant d\'orientation',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.blue[600]),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.containsKey("user");
                final isLoading = message["isLoading"] ?? false;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: 4,
                      top: 4,
                      left: isUser ? 60 : 0,
                      right: isUser ? 0 : 60,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFE5F3FD), // Couleurs iMessage
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(17),
                        topRight: const Radius.circular(17),
                        bottomLeft: Radius.circular(isUser ? 17 : 5),
                        bottomRight: Radius.circular(isUser ? 5 : 17),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 12,
                              child: Icon(
                                Icons.school,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Flexible(
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black54,
                                  ),
                                )
                              : Text(
                                  isUser ? message["user"]! : message["bot"]!,
                                  style: TextStyle(
                                    color:
                                        isUser ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -1),
                  blurRadius: 5,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
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
                      hintStyle: const TextStyle(color: Colors.black45),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black87,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _isLoading ? Colors.grey[400] : Colors.white,
                      size: 20,
                    ),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
