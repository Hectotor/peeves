import chromadb
import json

def test_chroma():
    print("Connexion à ChromaDB...")
    client = chromadb.HttpClient(host="127.0.0.1", port=8080)
    collection_id = "b0d61f11-ccae-4942-8680-400e8e9fa170"

    try:
        print("\n1. Vérification de la collection :")
        try:
            collection = client.get_collection(name=collection_id)
            print("Collection existante trouvée")
            
            print("\n2. Test de requête :")
            results = collection.query(
                query_texts=["formation informatique"],
                n_results=2
            )
            
            print("\nRésultats de la requête :")
            if results['documents'][0]:
                for doc in results['documents'][0]:
                    print(f"- {doc}")
                    
            print("\nTest terminé avec succès!")
            
        except Exception as e:
            print(f"Collection non trouvée ou erreur : {e}")
            print("Veuillez exécuter create_collection.py pour créer et remplir la collection")
            
    except Exception as e:
        print(f"\nErreur lors du test : {str(e)}")

if __name__ == "__main__":
    test_chroma()
