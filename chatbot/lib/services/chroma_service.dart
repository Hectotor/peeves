import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart'; // Ajoutez cette dépendance dans pubspec.yaml

class ChromaService {
  final String baseUrl;
  final http.Client client;
  static const _uuid = Uuid(); // Changé en static const
  static const String defaultCollectionId =
      'b0d61f11-ccae-4942-8680-400e8e9fa170'; // Ajout d'un UUID fixe pour la collection

  ChromaService({
    this.baseUrl = 'http://0.0.0.0:8000', // Changement de localhost à 0.0.0.0
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<bool> createCollection(String collectionName) async {
    try {
      print('Tentative de création de la collection avec UUID fixe');
      final response = await client.post(
        Uri.parse('$baseUrl/api/v1/collections'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': defaultCollectionId, // Utilisation de l'UUID fixe
          'metadata': {
            'description': 'Formations Parcoursup',
            'display_name':
                collectionName // Stockage du nom lisible dans les métadonnées
          },
        }),
      );

      print('Code status: ${response.statusCode}');
      print('Réponse: ${response.body}');

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la création: $e');
      return false;
    }
  }

  Future<void> addDocuments(
      String collectionName, List<Map<String, dynamic>> formations) async {
    try {
      // Préparer les données dans le format exact attendu par ChromaDB
      final List<String> documents = [];
      final List<String> ids = [];
      final List<Map<String, dynamic>> metadatas = [];
      final List<List<double>> embeddings = [];

      for (var formation in formations) {
        // Générer un UUID valide pour chaque document
        final String uuid = const Uuid().v4();
        print('Ajout document avec UUID: $uuid');

        documents.add(formation['nom_formation'] ?? '');
        ids.add(uuid); // Utiliser l'UUID généré
        metadatas.add(formation);
        embeddings.add(List.filled(1536, 0.0));
      }

      final response = await client.post(
        Uri.parse('$baseUrl/api/v1/collections/$defaultCollectionId/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'documents': documents,
          'ids': ids,
          'metadatas': metadatas,
          'embeddings': embeddings,
        }),
      );

      if (response.statusCode != 200) {
        print('Erreur ChromaDB: ${response.body}');
        throw Exception(
            'Erreur lors de l\'ajout des documents: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur détaillée: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryFormations(
      String collectionName, String query) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/v1/collections/$defaultCollectionId/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query_texts': [query],
          'n_results': 3,
          'include': ['metadatas', 'documents', 'distances'],
          'where': {}, // Filtre optionnel
          'where_document': {}, // Filtre optionnel sur le contenu
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Map<String, dynamic>> results = [];

        if (data['metadatas'] != null &&
            data['metadatas'].isNotEmpty &&
            data['metadatas'][0] is List) {
          final metadatas = data['metadatas'][0] as List;
          final documents = data['documents'][0] as List;

          for (var i = 0; i < metadatas.length; i++) {
            results.add({
              ...metadatas[i],
              'document': documents[i],
            });
          }
        }

        return results;
      }
      print('Erreur ChromaDB: ${response.body}');
      return [];
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      return [];
    }
  }

  Future<bool> checkCollection(String collectionName) async {
    try {
      print('Vérification de la collection avec UUID fixe');
      final response = await client.get(
        Uri.parse('$baseUrl/api/v1/collections/$defaultCollectionId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la vérification: $e');
      return false;
    }
  }
}
