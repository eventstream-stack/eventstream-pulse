from django.core.management.base import BaseCommand
from messages_app.models import TargetApp


class Command(BaseCommand):
    help = 'Seed the database with target apps'

    def handle(self, *args, **options):
        apps = [
            ('brighton', 'The Brighton App'),
            ('edinburgh', 'The Edinburgh App'),
            ('manchester', 'The Manchester App'),
            ('cardiff', 'The Cardiff App'),
            ('kilkenny', 'The Kilkenny App'),
            ('york', 'The York App'),
        ]

        for app_id, app_name in apps:
            obj, created = TargetApp.objects.get_or_create(
                app_id=app_id,
                defaults={'app_name': app_name}
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f'Created: {app_name}'))
            else:
                self.stdout.write(f'Already exists: {app_name}')

        self.stdout.write(self.style.SUCCESS('Done seeding target apps!'))
