import chromadb
import json

def init_chroma():
    # Initialiser le client ChromaDB
    client = chromadb.HttpClient(host="localhost", port=8000)
    
    try:
        # Créer une nouvelle collection
        collection = client.create_collection(
            name="formations_parcoursup",
            metadata={"description": "Base de données des formations Parcoursup"}
        )
        
        # Charger les données JSON
        with open('assets/formations_parcoursup.json', 'r', encoding='utf-8') as f:
            formations = json.load(f)
        
        # Préparer les données pour ChromaDB
        documents = []
        metadatas = []
        ids = []
        
        for idx, formation in enumerate(formations):
            # Créer un document texte pour chaque formation
            doc_text = f"{formation['nom_etablissement']} - {formation['nom_formation']} (Places disponibles: {formation['places_disponibles']})"
            documents.append(doc_text)
            
            # Métadonnées pour chaque formation
            metadatas.append({
                "nom_etablissement": formation['nom_etablissement'],
                "nom_formation": formation['nom_formation'],
                "places_disponibles": formation['places_disponibles']
            })
            
            # Identifiant unique pour chaque document
            ids.append(f"formation_{idx}")
        
        # Ajouter les documents à la collection
        collection.add(
            documents=documents,
            metadatas=metadatas,
            ids=ids
        )
        
        print(f"Ajout réussi de {len(documents)} formations à ChromaDB")
        
    except Exception as e:
        print(f"Erreur lors de l'initialisation de ChromaDB: {str(e)}")

if __name__ == "__main__":
    init_chroma()
