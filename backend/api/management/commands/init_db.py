"""
Management command to initialize the production database.
Runs migrations and seeds initial data (categories & challenges).
"""
from django.core.management.base import BaseCommand
from django.core.management import call_command


class Command(BaseCommand):
    help = 'Initializes the database for production: runs migrations and seeds essential data.'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE('1. Exécution des migrations...'))
        call_command('migrate', interactive=False)
        
        self.stdout.write(self.style.NOTICE('2. Initialisation des catégories par défaut...'))
        call_command('seed_categories')
        
        self.stdout.write(self.style.NOTICE('3. Initialisation des défis et badges de gamification...'))
        call_command('seed_challenges')
        
        self.stdout.write(self.style.SUCCESS('[OK] Base de donnees initialisee avec succes pour la production !'))
