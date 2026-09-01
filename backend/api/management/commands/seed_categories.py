"""
Management command to seed default categories.
Reproduces the exact same categories as the Flutter app.
"""
from django.core.management.base import BaseCommand
from api.models import Category


class Command(BaseCommand):
    help = 'Seed default transaction categories (same as Flutter app)'

    def handle(self, *args, **options):
        categories = [
            {
                'id': 'cat_food',
                'name': 'Alimentation',
                'icon': 'food',
                'color': '0xFFFF6B35',
                'type': 'expense',
            },
            {
                'id': 'cat_transport',
                'name': 'Transport',
                'icon': 'transport',
                'color': '0xFF4ECDC4',
                'type': 'expense',
            },
            {
                'id': 'cat_home',
                'name': 'Logement',
                'icon': 'home',
                'color': '0xFF45B7D1',
                'type': 'expense',
            },
            {
                'id': 'cat_leisure',
                'name': 'Loisirs',
                'icon': 'leisure',
                'color': '0xFF96CEB4',
                'type': 'expense',
            },
            {
                'id': 'cat_health',
                'name': 'Santé',
                'icon': 'health',
                'color': '0xFFFF6584',
                'type': 'expense',
            },
            {
                'id': 'cat_other_exp',
                'name': 'Autres',
                'icon': 'other',
                'color': '0xFFB8B8B8',
                'type': 'expense',
            },
            {
                'id': 'cat_salary',
                'name': 'Salaire',
                'icon': 'salary',
                'color': '0xFF2E7D32',
                'type': 'income',
            },
            {
                'id': 'cat_freelance',
                'name': 'Freelance',
                'icon': 'freelance',
                'color': '0xFF66BB6A',
                'type': 'income',
            },
            {
                'id': 'cat_invest',
                'name': 'Investissement',
                'icon': 'invest',
                'color': '0xFF81C784',
                'type': 'income',
            },
            {
                'id': 'cat_other_inc',
                'name': 'Autres',
                'icon': 'other',
                'color': '0xFFA5D6A7',
                'type': 'income',
            },
        ]

        created_count = 0
        for cat_data in categories:
            _, created = Category.objects.update_or_create(
                id=cat_data['id'],
                defaults={
                    'name': cat_data['name'],
                    'icon': cat_data['icon'],
                    'color': cat_data['color'],
                    'type': cat_data['type'],
                },
            )
            if created:
                created_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f'Categories seeded: {created_count} created, '
                f'{len(categories) - created_count} updated.'
            )
        )
