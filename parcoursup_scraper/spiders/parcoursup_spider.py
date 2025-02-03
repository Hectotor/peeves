
import scrapy
import pandas as pd
from datetime import datetime

class ParcoursupSpider(scrapy.Spider):
    name = 'parcoursup'
    start_urls = ['https://dossierappel.parcoursup.fr/Candidat/carte']
    
    custom_settings = {
        'ROBOTSTXT_OBEY': True,
        'FEED_FORMAT': 'xlsx',
        'FEED_URI': f'formations_parcoursup_{datetime.now().strftime("%Y%m%d")}.xlsx'
    }

    def parse(self, response):
        cards = response.css('.fr-card__content')
        donnees_etablissements = []

        for card in cards:
            info_etablissement = {
                'nom_etablissement': card.css('.psup-search-results-card__school-name::text').get(),
                'nom_formation': card.css('.psup-search-results-card__course-name::text').get(),
                'date_extraction': datetime.now().strftime("%Y-%m-%d")
            }
            donnees_etablissements.append(info_etablissement)

        df = pd.DataFrame(donnees_etablissements)
        df.to_excel(self.custom_settings['FEED_URI'], index=False)