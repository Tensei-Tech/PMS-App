from django.db import models


class FieldTemplate(models.Model):
    """
    Template grouping sets of common and custom fields.
    """
    template_id = models.BigAutoField(primary_key=True)
    template_name = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'field_templates'
        verbose_name = 'Field Template'
        verbose_name_plural = 'Field Templates'
        ordering = ['template_name']

    def __str__(self):
        return self.template_name


class FieldTemplateField(models.Model):
    """
    Individual field definitions attached to a FieldTemplate.
    """
    SOURCE_CHOICES = (
        ('common', 'Common Form Field'),
        ('custom', 'Section/Crime Specific Custom Field'),
    )
    TYPE_CHOICES = (
        ('text', 'Text Field'),
        ('textarea', 'Multi-line Text Area'),
        ('number', 'Numeric Field'),
        ('date', 'Date Picker'),
        ('datetime', 'Date-Time Picker'),
        ('dropdown', 'Dropdown Select'),
        ('checkbox', 'Checkbox Toggle'),
        ('chips', 'Chips Selector'),
        ('file', 'File Upload'),
    )

    field_def_id = models.BigAutoField(primary_key=True)
    template = models.ForeignKey(
        FieldTemplate,
        on_delete=models.CASCADE,
        related_name='fields',
        db_column='template_id'
    )
    field_label = models.CharField(max_length=100)
    field_key = models.CharField(max_length=50)
    field_source = models.CharField(max_length=10, choices=SOURCE_CHOICES, default='common')
    field_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='text')
    is_required = models.BooleanField(default=False)
    section = models.CharField(max_length=100, null=True, blank=True)
    display_order = models.IntegerField(default=0)

    class Meta:
        db_table = 'field_template_fields'
        verbose_name = 'Field Template Field'
        verbose_name_plural = 'Field Template Fields'
        ordering = ['display_order', 'field_def_id']

    def __str__(self):
        return f"{self.field_label} ({self.field_key}) [{self.template.template_name}]"


class CategoryFieldOverride(models.Model):
    """
    Per-category visibility overrides: hides a normally-common field for a specific category/sub-tab.
    """
    override_id = models.BigAutoField(primary_key=True)
    category = models.ForeignKey(
        'crimetab.CaseCategory',
        on_delete=models.CASCADE,
        related_name='field_overrides',
        db_column='category_id'
    )
    field_key = models.CharField(max_length=50)
    is_visible = models.BooleanField(default=True)

    class Meta:
        db_table = 'category_field_overrides'
        verbose_name = 'Category Field Override'
        verbose_name_plural = 'Category Field Overrides'
        unique_together = ('category', 'field_key')

    def __str__(self):
        status = "Visible" if self.is_visible else "Hidden"
        return f"Category {self.category.category_name} -> {self.field_key}: {status}"


class CategoryFieldTemplate(models.Model):
    """
    Associates a CaseCategory with one or more FieldTemplates (Trigger A).
    Allows a tab/category to link to both the shared baseline template and its own category-specific extra template(s).
    """
    id = models.BigAutoField(primary_key=True)
    category = models.ForeignKey(
        'crimetab.CaseCategory',
        on_delete=models.CASCADE,
        related_name='category_template_mappings',
        db_column='category_id'
    )
    template = models.ForeignKey(
        FieldTemplate,
        on_delete=models.CASCADE,
        related_name='category_mappings',
        db_column='template_id'
    )

    class Meta:
        db_table = 'category_field_templates'
        verbose_name = 'Category Field Template'
        verbose_name_plural = 'Category Field Templates'
        unique_together = ('category', 'template')

    def __str__(self):
        return f"Category {self.category.category_name} -> Template {self.template.template_name}"


class SectionFieldTemplate(models.Model):
    """
    Maps an ActSection to a FieldTemplate.
    When this section is selected in Charges, this template's extra fields unlock dynamically.
    """
    id = models.BigAutoField(primary_key=True)
    section = models.ForeignKey(
        'crimetab.ActSection',
        on_delete=models.CASCADE,
        related_name='section_mappings',
        db_column='section_id'
    )
    template = models.ForeignKey(
        FieldTemplate,
        on_delete=models.CASCADE,
        related_name='section_mappings',
        db_column='template_id'
    )

    class Meta:
        db_table = 'section_field_templates'
        verbose_name = 'Section Field Template'
        verbose_name_plural = 'Section Field Templates'

    def __str__(self):
        return f"Section {self.section.section_number} -> Template {self.template.template_name}"


class CaseExtraFieldValue(models.Model):
    """
    Stores values of custom / extra dynamic fields submitted for a case.
    """
    value_id = models.BigAutoField(primary_key=True)
    case = models.ForeignKey(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        related_name='extra_field_values',
        db_column='case_id'
    )
    field_def = models.ForeignKey(
        FieldTemplateField,
        on_delete=models.CASCADE,
        related_name='case_values',
        db_column='field_def_id'
    )
    field_value = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'case_extra_field_values'
        verbose_name = 'Case Extra Field Value'
        verbose_name_plural = 'Case Extra Field Values'
        unique_together = ('case', 'field_def')

    def __str__(self):
        return f"Case {self.case_id} -> {self.field_def.field_key}: {self.field_value[:30] if self.field_value else ''}"
