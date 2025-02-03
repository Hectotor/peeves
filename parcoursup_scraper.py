from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
import pandas as pd
import time

def setup_driver():
    # Configuration du navigateur Chrome
    options = webdriver.ChromeOptions()
    options.add_argument('--headless')  # Mode sans interface graphique
    options.add_argument('--lang=fr')   # Définir la langue en français
    return webdriver.Chrome(options=options)

def scrape_parcoursup():
    driver = setup_driver()
    try:
        print("Accès au site Parcoursup...")
        driver.get("https://dossierappel.parcoursup.fr/Candidat/carte")
        wait = WebDriverWait(driver, 10)
        
        # Configuration des filtres
        print("Configuration des filtres...")
        try:
            wait.until(EC.presence_of_element_located((By.CLASS_NAME, "fr-card__content")))
            
            # Désactiver d'abord le filtre des places vacantes
            driver.execute_script("""
                document.querySelector('#filter-hasPlaces').click();
            """)
            time.sleep(2)
            
            # Sélectionner le filtre "Publics"
            filtre_public = driver.execute_script("""
                const labels = Array.from(document.querySelectorAll('.psup-search-filter__label'));
                const publicLabel = labels.find(label => 
                    label.querySelector('.psup-search-filter__result-name').textContent.trim() === 'Publics'
                );
                if (publicLabel) {
                    publicLabel.click();
                    return true;
                }
                return false;
            """)
            
            if (filtre_public):
                print("Filtre 'Publics' activé")
                # Cliquer sur le bouton pour appliquer les filtres
                driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
                time.sleep(3)  # Attendre le rechargement
            else:
                print("Filtre 'Publics' non trouvé")
                
        except Exception as e:
            print(f"Erreur lors de la configuration des filtres : {str(e)}")

        donnees_etablissements = []
        page = 1
        total_cartes_scrapees = 0
        LIMITE_CARTES = 1500  # Limite fixée à 1500 cartes
        
        while True:
            print(f"\nTraitement de la page {page}...")
            
            # Attendre le chargement des cartes
            wait.until(EC.presence_of_element_located((By.CLASS_NAME, "fr-card__content")))
            time.sleep(2)
            
            # Utiliser JavaScript pour vérifier le nombre total de résultats
            total_results = driver.execute_script("""
                return document.querySelectorAll('.fr-card__content').length;
            """)
            
            if total_results == 0:
                print("Aucun résultat trouvé.")
                break
                
            # Récupérer les cartes
            cards = driver.find_elements(By.CLASS_NAME, "fr-card__content")
            print(f"Nombre de cartes trouvées : {len(cards)}")
            
            for index, card in enumerate(cards, 1):
                if total_cartes_scrapees >= LIMITE_CARTES:
                    print(f"\nLimite de {LIMITE_CARTES} cartes atteinte.")
                    break
                    
                try:
                    # Extraction du nombre de places disponibles avec meilleur nettoyage
                    places_element = card.find_element(By.CSS_SELECTOR, ".fr-badge.fr-badge--sm.fr-badge--info.fr-badge--no-icon")
                    places_text = places_element.text
                    # Extraction du nombre en utilisant une meilleure méthode
                    import re
                    places_match = re.search(r'\d+', places_text)
                    places = int(places_match.group()) if places_match else 0
                    
                    info_etablissement = {
                        'nom_etablissement': card.find_element(By.CLASS_NAME, "psup-search-results-card__school-name").text,
                        'nom_formation': card.find_element(By.CLASS_NAME, "psup-search-results-card__course-name").text,
                        'places_disponibles': places,
                        'date_extraction': time.strftime("%Y-%m-%d"),
                        'page': page
                    }
                    donnees_etablissements.append(info_etablissement)
                    total_cartes_scrapees += 1
                    print(f"Carte {total_cartes_scrapees}/{LIMITE_CARTES} traitée")
                    
                except Exception as e:
                    print(f"Erreur lors du traitement de la carte : {str(e)}")
                    continue
            
            if total_cartes_scrapees >= LIMITE_CARTES:
                break
                
            # Navigation à la page suivante via JavaScript
            try:
                has_next = driver.execute_script("""
                    const nextBtn = document.querySelector('button.fr-pagination__link--next');
                    if (nextBtn && !nextBtn.disabled) {
                        nextBtn.click();
                        return true;
                    }
                    return false;
                """)
                
                if not has_next:
                    print("Plus de pages suivantes.")
                    break
                    
                page += 1
                time.sleep(3)  # Attendre le chargement de la nouvelle page
                
            except Exception as e:
                print(f"Erreur de navigation : {str(e)}")
                break

        # Enregistrement des données dans Excel...
        print(f"\nEnregistrement des données de {len(donnees_etablissements)} formations...")
        df = pd.DataFrame(donnees_etablissements)
        nom_fichier = f'formations_parcoursup_{time.strftime("%Y%m%d")}.xlsx'
        
        # Sauvegarde dans Excel avec mise en forme
        with pd.ExcelWriter(nom_fichier, engine='openpyxl') as writer:
            df.to_excel(writer, sheet_name='Formations', index=False)
            # Ajustement automatique de la largeur des colonnes
            worksheet = writer.sheets['Formations']
            for idx, col in enumerate(df.columns):
                max_length = max(df[col].astype(str).apply(len).max(), len(col))
                worksheet.column_dimensions[chr(65 + idx)].width = max_length + 2
                
        print(f"Données sauvegardées dans le fichier : {nom_fichier}")
        
    except Exception as e:
        print(f"Une erreur s'est produite : {str(e)}")
    finally:
        driver.quit()

if __name__ == "__main__":
    print("Démarrage de l'extraction des données Parcoursup...")
    scrape_parcoursup()
