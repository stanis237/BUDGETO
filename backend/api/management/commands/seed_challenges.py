from django.core.management.base import BaseCommand
from api.models import Challenge

class Command(BaseCommand):
    help = 'Seeds the database with default gamification challenges'

    def handle(self, *args, **kwargs):
        challenges = [
            {
                'title': 'Premier pas !',
                'description': 'Ajouter votre première transaction dans Budgeto.',
                'points': 10,
                'icon': 'emoji_events',
                'color': '0xFFFFD700',
            },
            {
                'title': 'Économe du mois',
                'description': 'Rester en dessous de 80% du budget Alimentation ce mois-ci.',
                'points': 50,
                'icon': 'restaurant',
                'color': '0xFFFF6B35',
            },
            {
                'title': 'Week-end sans dépense',
                'description': 'Ne rien dépenser pendant tout le samedi et le dimanche.',
                'points': 100,
                'icon': 'weekend',
                'color': '0xFF4CAF50',
            },
            {
                'title': 'Visionnaire',
                'description': 'Créer votre premier plan budgétaire mensuel.',
                'points': 20,
                'icon': 'visibility',
                'color': '0xFF2196F3',
            },
        ]

        created_count = 0
        for data in challenges:
            obj, created = Challenge.objects.get_or_create(
                title=data['title'],
                defaults=data
            )
            if created:
                created_count += 1
                
        self.stdout.write(self.style.SUCCESS(f'Challenges seeded: {created_count} created.'))
