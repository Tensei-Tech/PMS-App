from django.db import migrations

# Officers edit only their own cases (created by them or assigned to them as
# IO): 'case:edit_own' stays, the broad 'case:edit' is taken away.


def revoke_broad_case_edit(apps, schema_editor):
    RolePermission = apps.get_model('public_master', 'RolePermission')
    RolePermission.objects.filter(role_id='officer', permission_id='case:edit').update(is_granted=False)


def restore_broad_case_edit(apps, schema_editor):
    RolePermission = apps.get_model('public_master', 'RolePermission')
    RolePermission.objects.filter(role_id='officer', permission_id='case:edit').update(is_granted=True)


class Migration(migrations.Migration):

    dependencies = [
        ('public_master', '0017_apply_designation_matrix'),
    ]

    operations = [
        migrations.RunPython(revoke_broad_case_edit, restore_broad_case_edit),
    ]
