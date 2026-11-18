from django.db import migrations, models

"""
Migration 0192: sub-tabs of dashboard tiles in their own table (dashboard_subtabs).

Murder (Murder / Attempt to Murder), Dacoity (Dacoity / Robbery), Cheating
(Cheating / CBT), Passport/PVR/Licence (Passport / Licence / PVR),
NAFIS/Fingerprint, DAR/IRAD and Disposal (Form 1 to 5 / Form 6) had their
sub-tabs written in the app. Now each sub-tab is one row, linked to its tile by
parent_key (the tile's module_key), and the app builds them from the active
rows in display_order.

Shared by all states, so the table is created in public (like dashboard_tiles).
Running it again adds nothing twice; going backwards keeps the table.
"""

CREATE_SQL = """
CREATE TABLE IF NOT EXISTS public.dashboard_subtabs (
    id BIGSERIAL PRIMARY KEY,
    parent_key VARCHAR(100) NOT NULL,
    label VARCHAR(150) NOT NULL,
    screen_key VARCHAR(100) NOT NULL DEFAULT 'category',
    icon VARCHAR(100) NOT NULL DEFAULT '',
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT dashboard_subtabs_parent_key_label_uniq UNIQUE (parent_key, label)
);
CREATE INDEX IF NOT EXISTS dashboard_subtabs_parent_idx ON public.dashboard_subtabs (parent_key);
"""

# parent_key (tile module_key) -> [(label, screen_key, icon)], in tab order
SUBTABS = {
    'murder': [
        ('Murder', 'category', 'gavel_rounded'),
        ('Attempt to Murder', 'category', 'gavel_rounded'),
    ],
    'dacoity': [
        ('Dacoity', 'category', 'lock_outline_rounded'),
        ('Robbery', 'category', 'lock_outline_rounded'),
    ],
    'cheating': [
        ('Cheating', 'category', 'receipt_long_outlined'),
        ('CBT', 'category', 'receipt_long_outlined'),
    ],
    'passport': [
        ('Passport', 'passport', 'badge_rounded'),
        ('PVR', 'pvr', 'fact_check_rounded'),
        ('Licence', 'licence', 'assignment_ind_rounded'),
    ],
    'nafis': [
        ('NAFIS', 'nafis', 'fingerprint_rounded'),
        ('Fingerprint', 'fingerprint', 'touch_app_rounded'),
    ],
    'dar': [
        ('DAR', 'dar', 'folder_rounded'),
        ('IRAD', 'irad', 'analytics_rounded'),
    ],
    'disposal': [
        ('Form 1 to 5', 'disposal_form_1_5', 'description_rounded'),
        ('Form 6', 'disposal_form_6', 'gavel_rounded'),
    ],
}


def create_table(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(CREATE_SQL)
    else:
        schema_editor.create_model(apps.get_model('crimetab', 'DashboardSubtab'))


def seed_subtabs(apps, schema_editor):
    DashboardSubtab = apps.get_model('crimetab', 'DashboardSubtab')
    for parent_key, tabs in SUBTABS.items():
        for i, (label, screen_key, icon) in enumerate(tabs, start=1):
            DashboardSubtab.objects.get_or_create(
                parent_key=parent_key, label=label,
                defaults={'screen_key': screen_key, 'icon': icon,
                          'display_order': i * 10, 'is_active': True},
            )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0191_dashboard_tiles'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                # Going backwards keeps the table and its rows (nothing is dropped)
                migrations.RunPython(create_table, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.CreateModel(
                    name='DashboardSubtab',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('parent_key', models.CharField(max_length=100)),
                        ('label', models.CharField(max_length=150)),
                        ('screen_key', models.CharField(default='category', max_length=100)),
                        ('icon', models.CharField(blank=True, default='', max_length=100)),
                        ('display_order', models.IntegerField(default=0)),
                        ('is_active', models.BooleanField(default=True)),
                    ],
                    options={
                        'verbose_name': 'Dashboard Sub-tab',
                        'verbose_name_plural': 'Dashboard Sub-tabs',
                        'db_table': 'dashboard_subtabs',
                        'ordering': ['parent_key', 'display_order', 'id'],
                        'unique_together': {('parent_key', 'label')},
                    },
                ),
            ],
        ),
        migrations.RunPython(seed_subtabs, reverse_code=migrations.RunPython.noop),
    ]
