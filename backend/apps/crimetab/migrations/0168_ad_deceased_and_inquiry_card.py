from django.db import migrations

"""
Migration 0168: A.D. sections 2 to 7 share one card (data only)

Deceased Details, Post Mortem, Preserve, FSL / CA, Cause of Death and
Procedural Details now open in one collapsible card, CARD_TITLE. Each keeps
its own section name, shown as a heading inside the card (and unchanged in
the View / PDF). The form groups sections by field_config 'card'.
Idempotent; backwards removes the 'card' key so each section is a card again.
"""

TEMPLATE_NAME = 'AD Form Fields'
CARD_TITLE = 'Deceased & Inquiry Details'
SECTIONS = [
    'Deceased Details',
    'Post Mortem',
    'Preserve',
    'FSL / CA',
    'Cause of Death',
    'Procedural Details',
]


def _fields(apps):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    return FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, section__in=SECTIONS)


def forwards(apps, schema_editor):
    for f in _fields(apps):
        config = dict(f.field_config or {})
        if config.get('card') != CARD_TITLE:
            config['card'] = CARD_TITLE
            f.field_config = config
            f.save(update_fields=['field_config'])


def backwards(apps, schema_editor):
    for f in _fields(apps):
        config = dict(f.field_config or {})
        if config.pop('card', None) is not None:
            f.field_config = config
            f.save(update_fields=['field_config'])


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0167_ad_yes_no_to_checkboxes'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
