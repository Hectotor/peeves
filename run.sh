#!/bin/bash

# Activer l'environnement virtuel s'il existe, sinon le créer
if [ ! -d "venv" ]; then
    echo "Création de l'environnement virtuel..."
    python3 -m venv venv
fi

source venv/bin/activate

# Installer les dépendances
echo "Installation des dépendances..."
pip3 install -r requirements.txt

# Exécuter le script
echo "Exécution du script..."
python3 parcoursup_scraper.py
