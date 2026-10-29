from django.db import migrations
from django.db.models import Q

"""
Migration 0137: "Cheating Extra Fields" for Cheating category (data only)

Template: "Cheating Extra Fields" (store_values_in_table = True)
Linked to: Cheating category (code 109, name 'Cheating')

Sections:
1. Type of Cheating
   - Cash (radio, Yes/No)
   - Cash Amount (₹) (number, depends on Cash == 'Yes')
   - Online Send (radio, Yes/No)
   - Online Send Amount (₹) (number, depends on Online Send == 'Yes')
   - Bank Withdraw (radio, Yes/No)
   - Bank Withdraw Amount (₹) (number, depends on Bank Withdraw == 'Yes')
   - Total Value (₹) (number, auto-sum: cheating_cash_amount,cheating_online_amount,cheating_bank_withdraw_amount)

2. Victim Details
   - Victim (how many victims were there) (number with stepper, options_source: 'stepper')
   - Victims (repeating_group)
     - Name (text, parent: cheating_victims)
     - Age (number, parent: cheating_victims, options_source: 'digits:3')
     - Gender (dropdown, parent: cheating_victims, options_source: '/api/options/gender/')

Answers are stored as rows in tenant case_extra_field_values table.
Idempotent.
"""

TEMPLATE_NAME = 'Cheating Extra Fields'
CATEGORY_NAME = 'Cheating'
CATEGORY_CODE = '109'
YES_NO = '/api/options/yes_no/'
GENDER = '/api/options/gender/'
YES = 'Yes'

SEC_TYPE = 'Type of Cheating'
SEC_VICTIM = 'Victim Details'

# (label, key, type, section, order, depends_on_key, depends_on_val, options_source, parent_field_key)
FIELDS = [
    ('Cash', 'cheating_cash', 'radio', SEC_TYPE, 10, None, None, YES_NO, None),
    ('Cash Amount (₹)', 'cheating_cash_amount', 'number', SEC_TYPE, 20, 'cheating_cash', YES, None, None),

    ('Online Send', 'cheating_online_send', 'radio', SEC_TYPE, 30, None, None, YES_NO, None),
    ('Online Send Amount (₹)', 'cheating_online_amount', 'number', SEC_TYPE, 40, 'cheating_online_send', YES, None, None),

    ('Bank Withdraw', 'cheating_bank_withdraw', 'radio', SEC_TYPE, 50, None, None, YES_NO, None),
    ('Bank Withdraw Amount (₹)', 'cheating_bank_withdraw_amount', 'number', SEC_TYPE, 60, 'cheating_bank_withdraw', YES, None, None),

    ('Total Value (₹)', 'cheating_total_value', 'number', SEC_TYPE, 70, None, None,
     'sum:cheating_cash_amount,cheating_online_amount,cheating_bank_withdraw_amount', None),

    ('Victim (how many victims were there)', 'cheating_victim_count', 'number', SEC_VICTIM, 100, None, None, 'stepper', None),

    ('Victims', 'cheating_victims', 'repeating_group', SEC_VICTIM, 110, None, None, None, None),
    ('Name', 'cheating_victim_name', 'text', SEC_VICTIM, 111, None, None, None, 'cheating_victims'),
    ('Age', 'cheating_victim_age', 'number', SEC_VICTIM, 112, None, None, 'digits:3', 'cheating_victims'),
    ('Gender', 'cheating_victim_gender', 'dropdown', SEC_VICTIM, 113, None, None, GENDER, 'cheating_victims'),
]


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    tmpl, _ = FieldTemplate.objects.update_or_create(
        template_name=TEMPLATE_NAME, defaults={'store_values_in_table': True}
    )
    for label, key, ftype, section, order, parent_k, parent_v, opt_src, grp in FIELDS:
        FieldTemplateField.objects.update_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': ftype,
                'is_required': False,
                'section': section,
                'display_order': order,
                'options_source': opt_src,
                'depends_on_field_key': parent_k,
                'depends_on_value': parent_v,
                'parent_field_key': grp or '',
            },
        )

    for cat in CaseCategory.objects.filter(Q(category_code=CATEGORY_CODE) | Q(category_name__iexact=CATEGORY_NAME)):
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if not tmpl:
        return
    CategoryFieldTemplate.objects.filter(template=tmpl).delete()
    FieldTemplateField.objects.filter(template=tmpl).delete()
    tmpl.delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0136_chain_snatching_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
