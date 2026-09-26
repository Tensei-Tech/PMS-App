from django.db import models


class CaseCategoryGroup(models.Model):
    """
    Crime Tab Grouping: e.g. '1 to 5' (Group Code 'I TO V'), 'Part 6' (Group Code 'VI').
    """
    group_id = models.BigAutoField(primary_key=True)
    group_name = models.CharField(max_length=50)
    group_code = models.CharField(max_length=10, blank=True, null=True)
    display_order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'case_category_groups'
        verbose_name = 'Case Category Group'
        verbose_name_plural = 'Case Category Groups'
        ordering = ['display_order', 'group_id']

    def __str__(self):
        return f"{self.group_name} ({self.group_code or 'No Code'})"


class CaseCategory(models.Model):
    """
    Sub-tab / Standalone Category (e.g. Murder, Theft, POCSO, NDPS).
    If group_id is NULL, this category is a top-level Standalone tab.
    """
    category_id = models.BigAutoField(primary_key=True)
    group = models.ForeignKey(
        CaseCategoryGroup,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='categories',
        db_column='group_id'
    )
    category_name = models.CharField(max_length=100)
    category_code = models.CharField(max_length=50, blank=True, null=True)
    parent_category = models.ForeignKey(
        'self',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='nested_subcategories',
        db_column='parent_category_id'
    )
    template = models.ForeignKey(
        'crimetab.FieldTemplate',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='categories',
        db_column='template_id'
    )
    display_order = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'case_categories'
        verbose_name = 'Case Category'
        verbose_name_plural = 'Case Categories'
        ordering = ['display_order', 'category_id']

    def __str__(self):
        group_str = f" [{self.group.group_name}]" if self.group else " [Standalone]"
        return f"{self.category_name}{group_str}"


class CaseCategoryLink(models.Model):
    """
    M2M linkage between a CaseRecord and a CaseCategory.
    Allows a case to appear in both group sub-tab (e.g. 1 to 5 Theft) and standalone tab (Theft).
    """
    link_id = models.BigAutoField(primary_key=True)
    case = models.ForeignKey(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        related_name='category_links',
        db_column='case_id'
    )
    category = models.ForeignKey(
        CaseCategory,
        on_delete=models.CASCADE,
        related_name='case_links',
        db_column='category_id'
    )
    is_primary = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'case_category_links'
        verbose_name = 'Case Category Link'
        verbose_name_plural = 'Case Category Links'
        unique_together = ('case', 'category')
        indexes = [
            models.Index(fields=['case'], name='idx_ccl_case'),
            models.Index(fields=['category'], name='idx_ccl_category'),
        ]

    def __str__(self):
        return f"Case {self.case_id} <-> {self.category.category_name}"
