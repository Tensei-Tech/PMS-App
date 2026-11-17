from django.core.management.base import BaseCommand, CommandError

from apps.core.migration_safety import unreviewed_dangerous_migrations


class Command(BaseCommand):
    help = ('List new migrations that drop, rename, delete or truncate and are not marked '
            '`reviewed_dangerous`. Exits with an error when there is one (used by CI).')

    def handle(self, *args, **options):
        found = unreviewed_dangerous_migrations()
        if not found:
            self.stdout.write(self.style.SUCCESS('No unreviewed dangerous migrations.'))
            return
        for key, reasons in found:
            self.stdout.write(self.style.ERROR(key))
            for reason in reasons:
                self.stdout.write(f'  - {reason}')
        raise CommandError(
            f'{len(found)} dangerous migration(s) need a review. Check them on a copy of the database, then '
            "add reviewed_dangerous = '<what you checked>' to the Migration class.")
