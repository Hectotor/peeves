#!/usr/bin/env python3

try:
    import pandas as pd
except ImportError:
    print("Le module pandas n'est pas installé. Veuillez l'installer en utilisant 'pip install pandas'.")
    exit(1)

# Charger le fichier Excel
df = pd.read_excel('formations_parcoursup_20250130.xlsx')

# Convertir en JSON
json_data = df.to_json(orient='records', force_ascii=False)

# Sauvegarder le fichier JSON
with open('formations_parcoursup.json', 'w', encoding='utf-8') as f:
    f.write(json_data)

print("Conversion terminée. Le fichier JSON a été sauvegardé sous le nom 'formations_parcoursup.json'.")
