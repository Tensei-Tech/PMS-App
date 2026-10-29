from django.db import migrations

"""
Migration 0091: N.C. form layout (data only)

1. Preventive row: "Preventive Number" moves right after "Date"
   (Non Applicant, Provision, Date, Preventive Number, Outward Number, Bond Date,
   Bond Cancellation Date).
2. Registered By: "Registered By Designation" is labelled "Designation".
"""

TEMPLATE_NAME = 'NC Form'

# field_key: (new display_order, old display_order)
ORDER = {
    'nc_prev_number': (104, 107),
    'nc_prev_outward_no': (105, 104),
    'nc_prev_bond_date': (106, 105),
    'nc_prev_bond_cancel_date': (107, 106),
}
LABELS = {
    # field_key: (new label, old label)
    'nc_reg_designation': ('Designation', 'Registered By Designation'),
}


def _apply(apps, new_first):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    fields = FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)
    for key, (new, old) in ORDER.items():
        to, frm = (new, old) if new_first else (old, new)
        fields.filter(field_key=key, display_order=frm).update(display_order=to)
    for key, (new, old) in LABELS.items():
        to, frm = (new, old) if new_first else (old, new)
        fields.filter(field_key=key, field_label=frm).update(field_label=to)


def forwards(apps, schema_editor):
    _apply(apps, new_first=True)


def backwards(apps, schema_editor):
    _apply(apps, new_first=False)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0090_nc_list_card_settings'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
