"""E3: backup_database keeps the newest copies and needs PostgreSQL."""
import os
import tempfile
import time
from pathlib import Path

from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import SimpleTestCase

from apps.core.management.commands.backup_database import Command, find_tool


class BackupDatabaseTests(SimpleTestCase):

    def test_only_the_newest_backups_are_kept(self):
        with tempfile.TemporaryDirectory() as folder:
            for i in range(5):
                path = Path(folder, f'pms_db_2026111{i}_1200.dump')
                path.write_bytes(b'x')
                os.utime(path, (time.time() + i, time.time() + i))
            Path(folder, 'other.txt').write_text('kept')
            removed = Command()._keep_newest(Path(folder), 'db', keep=3)
            self.assertEqual(removed, 2)
            self.assertEqual(sorted(p.name for p in Path(folder).iterdir()),
                             ['other.txt', 'pms_db_20261112_1200.dump', 'pms_db_20261113_1200.dump',
                              'pms_db_20261114_1200.dump'])

    def test_needs_postgresql(self):
        with self.assertRaises(CommandError):  # the test database is SQLite
            call_command('backup_database', '--dir', tempfile.gettempdir())

    def test_pg_bin_dir_is_used_first(self):
        with tempfile.TemporaryDirectory() as folder:
            exe = 'pg_dump' + ('.exe' if os.name == 'nt' else '')
            Path(folder, exe).write_text('')
            os.environ['PG_BIN_DIR'] = folder
            try:
                self.assertEqual(find_tool('pg_dump'), str(Path(folder, exe)))
            finally:
                del os.environ['PG_BIN_DIR']
