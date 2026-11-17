"""
python manage.py backup_database [--dir PATH] [--keep N]

A full copy of the database (step E3: the Supabase Free plan keeps no backups
you can restore). It runs pg_dump with the connection in backend/.env and saves
one file per run:

    <dir>/pms_<database host>_<YYYYMMDD_HHMM>.dump     (default dir: ~/PMS_backups)

Only our schemas are copied: public and every state schema (not Supabase's own
auth / storage / realtime schemas). The file is checked with pg_restore --list
after writing, and only the newest N backups are kept (default 10).

The file holds personal data: keep the folder private, never in the repository
or a shared drive. Restore (into an empty or test database first):

    pg_restore --no-owner --no-privileges -d "<database url>" <file>.dump

pg_dump must be installed (PostgreSQL client tools). It is found on PATH, in
PG_BIN_DIR, or in C:\\Program Files\\PostgreSQL\\<version>\\bin.
"""
import datetime
import glob
import os
import re
import shutil
import subprocess
from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError


def find_tool(name):
    """pg_dump / pg_restore: PG_BIN_DIR, then PATH, then the newest Windows install."""
    exe = name + ('.exe' if os.name == 'nt' else '')
    bin_dir = os.getenv('PG_BIN_DIR')
    if bin_dir and Path(bin_dir, exe).exists():
        return str(Path(bin_dir, exe))
    found = shutil.which(name)
    if found:
        return found
    installs = sorted(glob.glob(os.path.join(r'C:\Program Files\PostgreSQL', '*', 'bin', exe)),
                      key=lambda p: int(re.search(r'PostgreSQL\\(\d+)', p).group(1)), reverse=True)
    return installs[0] if installs else None


def our_schemas():
    from apps.core.state_schema import active_state_schemas
    return ['public'] + [s for s in active_state_schemas() if s != 'public']


class Command(BaseCommand):
    help = 'Save a full copy of the database (public + state schemas) with pg_dump, keeping the newest N.'

    def add_arguments(self, parser):
        parser.add_argument('--dir', default=str(Path.home() / 'PMS_backups'),
                            help='Folder for the backup files (default: ~/PMS_backups). Keep it private.')
        parser.add_argument('--keep', type=int, default=10, help='How many backups to keep (default 10).')

    def handle(self, *args, dir=None, keep=10, **options):
        db = settings.DATABASES['default']
        if db['ENGINE'] != 'django.db.backends.postgresql':
            raise CommandError('backup_database works on PostgreSQL only.')
        pg_dump, pg_restore = find_tool('pg_dump'), find_tool('pg_restore')
        if not pg_dump:
            raise CommandError('pg_dump was not found. Install the PostgreSQL client tools or set PG_BIN_DIR.')

        folder = Path(dir).expanduser()
        folder.mkdir(parents=True, exist_ok=True)
        host = str(db.get('HOST') or 'localhost')
        label = re.sub(r'[^a-z0-9]+', '-', host.split('.')[0].lower()).strip('-') or 'db'
        stamp = datetime.datetime.now().strftime('%Y%m%d_%H%M')
        target = folder / f'pms_{label}_{stamp}.dump'

        env = {**os.environ, 'PGPASSWORD': str(db.get('PASSWORD') or '')}
        sslmode = (db.get('OPTIONS') or {}).get('sslmode')
        if sslmode:
            env['PGSSLMODE'] = sslmode
        schemas = our_schemas()
        cmd = [pg_dump, '--format=custom', '--no-owner', '--no-privileges',
               '-h', host, '-p', str(db.get('PORT') or 5432), '-U', str(db.get('USER') or ''),
               '-d', str(db.get('NAME') or ''), '-f', str(target)]
        for schema in schemas:
            cmd += ['-n', schema]

        self.stdout.write(f'Backing up schemas {", ".join(schemas)} from {host} ...')
        result = subprocess.run(cmd, env=env, capture_output=True, text=True)
        if result.returncode != 0:
            target.unlink(missing_ok=True)
            raise CommandError(f'pg_dump failed: {result.stderr.strip()[:500]}')

        entries = None
        if pg_restore:
            listed = subprocess.run([pg_restore, '--list', str(target)], capture_output=True, text=True)
            if listed.returncode != 0:
                raise CommandError(f'The backup file could not be read back: {listed.stderr.strip()[:300]}')
            entries = sum(1 for line in listed.stdout.splitlines() if line and not line.startswith(';'))

        size_mb = target.stat().st_size / (1024 * 1024)
        removed = self._keep_newest(folder, label, keep)
        self.stdout.write(self.style.SUCCESS(
            f'Saved {target} ({size_mb:.1f} MB'
            + (f', {entries} objects' if entries is not None else '') + ')'
            + (f'; removed {removed} older backup(s)' if removed else '')))

    def _keep_newest(self, folder, label, keep):
        files = sorted(folder.glob(f'pms_{label}_*.dump'), key=lambda p: p.stat().st_mtime, reverse=True)
        old = files[max(keep, 1):]
        for path in old:
            path.unlink()
        return len(old)
