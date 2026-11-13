from django.db import migrations

"""
Migration 0057: placeholder (does nothing)

The original 0057 ran on the shared database on 14 Oct 2026 and unlinked the
"Common Form Baseline Template" from the Road Accident tabs. Its file was
deleted afterwards and was never committed. Migration 0103 links the template
again, so the original change is already undone.

This empty file puts 0057 back in the history, so every database runs the same
list of migrations as the shared one.
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0056_road_accident_tenant_tables'),
    ]

    operations = []
