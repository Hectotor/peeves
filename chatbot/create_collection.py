import chromadb
import json
import time
import os

def create_and_fill_collection():
    print("Initialisation de ChromaDB...")
    client = chromadb.HttpClient(host="127.0.0.1", port=8080)
    collection_id = "b0d61f11-ccae-4942-8680-400e8e9fa170"

    try:
        # 1. Vérifier que le fichier JSON existe
        json_path = 'assets/formations_parcoursup.json'
        if not os.path.exists(json_path):
            print(f"ERREUR: Le fichier {json_path} n'existe pas!")
            return

        # 2. Supprimer l'ancienne collection
        try:
            print("Nettoyage de l'ancienne collection...")
            client.delete_collection(name=collection_id)
            time.sleep(2)  # Attendre après la suppression
        except:
            print("Pas d'ancienne collection à supprimer")

        # 3. Créer la nouvelle collection
        print("\nCréation de la collection...")
        collection = client.create_collection(
            name=collection_id,
            metadata={"description": "Formations Parcoursup"}
        )
        time.sleep(2)  # Attendre après la création

        # 4. Charger et vérifier les données
        print("\nChargement des données...")
        with open(json_path, 'r', encoding='utf-8') as f:
            formations = json.load(f)
            if not formations:
                print("ERREUR: Le fichier JSON est vide!")
                return
            print(f"Nombre de formations trouvées : {len(formations)}")

        # 5. Ajouter les documents
        batch_size = 50  # Plus petit lot pour plus de stabilité
        for i in range(0, len(formations), batch_size):
            end = min(i + batch_size, len(formations))
            batch = formations[i:end]
            
            print(f"Ajout du lot {i//batch_size + 1}/{len(formations)//batch_size + 1}...")
            collection.add(
                documents=[f"{f['nom_etablissement']} - {f['nom_formation']}" for f in batch],
                metadatas=[{
                    "nom_etablissement": f['nom_etablissement'],
                    "nom_formation": f['nom_formation'],
                    "places_disponibles": f['places_disponibles']
                } for f in batch],
                ids=[f"formation_{j}" for j in range(i, end)]
            )
            time.sleep(1)  # Attendre entre les lots

        # 6. Vérifier que tout a bien été ajouté
        test_query = collection.query(
            query_texts=["informatique"],
            n_results=1
        )
        if test_query['documents'][0]:
            print(f"\nSuccès! Collection créée et testée avec {len(formations)} formations")
            print("Test de recherche réussi :", test_query['documents'][0][0])
        else:
            print("\nERREUR: La collection semble vide après l'ajout")

    except Exception as e:
        print(f"\nERREUR: {str(e)}")

if __name__ == "__main__":
    create_and_fill_collection()
