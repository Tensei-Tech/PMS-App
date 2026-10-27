from django.db import migrations


def apply_designation_matrix(apps, schema_editor):
    from apps.public_master.designation_matrix import apply_matrix
    apply_matrix(apps.get_model('public_master', 'Designation'))


class Migration(migrations.Migration):

    dependencies = [
        ('public_master', '0016_dynamicuiconfig'),
    ]

    operations = [
        # Data only: the old flags are not restored on reverse.
        migrations.RunPython(apply_designation_matrix, migrations.RunPython.noop),
    ]
