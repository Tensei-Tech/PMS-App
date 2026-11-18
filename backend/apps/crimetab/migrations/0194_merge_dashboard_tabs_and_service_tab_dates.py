from django.db import migrations

"""
Migration 0194: joins the two migrations that both followed 0189.

  0190_service_tab_dates_with_time   (service tab dates) -> 0190 only
  0190_hide_licence_dashboard_tile   (dashboard tables)  -> 0191 -> 0192 -> 0193

Both were already applied to the shared database under these names, so they
are joined here instead of being renumbered.

It also puts the Passport/PVR/Licence sub-tabs in the order the app now uses
(Passport, PVR, Licence); 0192 had stored Passport, Licence, PVR.
"""

PASSPORT_ORDER = {'Passport': 10, 'PVR': 20, 'Licence': 30}


def passport_subtab_order(apps, schema_editor):
    DashboardSubtab = apps.get_model('crimetab', 'DashboardSubtab')
    for label, order in PASSPORT_ORDER.items():
        DashboardSubtab.objects.filter(parent_key='passport', label=label).update(display_order=order)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0190_service_tab_dates_with_time'),
        ('crimetab', '0193_form_1_5_and_form_6_tabs'),
    ]

    operations = [
        migrations.RunPython(passport_subtab_order, reverse_code=migrations.RunPython.noop),
    ]
