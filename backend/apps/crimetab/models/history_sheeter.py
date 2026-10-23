from django.db import models
from django.contrib.postgres.fields import ArrayField
import json


class SafeArrayField(ArrayField):
    """
    Subclasses ArrayField to gracefully support SQLite during test execution.
    In PostgreSQL, delegates completely to PostgreSQL native ArrayField.
    """
    def check(self, **kwargs):
        errors = super().check(**kwargs)
        return [e for e in errors if e.id != 'postgres.E005']

    def db_type(self, connection):
        if connection.vendor == 'sqlite':
            return 'text'
        return super().db_type(connection)

    def get_placeholder_sql(self, value, compiler, connection):
        # ArrayField appends a ::type[] cast that SQLite cannot parse
        if connection.vendor == 'sqlite':
            if hasattr(value, 'as_sql'):
                return compiler.compile(value)
            return '%s', (value,)
        return super().get_placeholder_sql(value, compiler, connection)

    def get_db_prep_save(self, value, connection):
        if connection.vendor == 'sqlite':
            return json.dumps(value) if value is not None else None
        return super().get_db_prep_save(value, connection)

    def get_db_prep_value(self, value, connection, prepared=False):
        if connection.vendor == 'sqlite':
            return json.dumps(value) if value is not None else None
        return super().get_db_prep_value(value, connection, prepared=prepared)

    def from_db_value(self, value, expression, connection):
        if connection.vendor == 'sqlite' and isinstance(value, str):
            try:
                return json.loads(value)
            except Exception:
                return []
        # ArrayField defines no from_db_value; psycopg already returns a list
        parent = getattr(super(), 'from_db_value', None)
        return parent(value, expression, connection) if parent else value


class HistorySheeter(models.Model):
    """
    History Sheeter main record stored inside state tenant schema (e.g. `<schema>.history_sheeters`).
    """
    id = models.BigAutoField(primary_key=True)
    station_name = models.CharField(max_length=255)
    sr_no = models.BigIntegerField()
    name = models.CharField(max_length=255, blank=True, null=True)
    alias = models.CharField(max_length=255, blank=True, null=True)
    nickname = models.CharField(max_length=255, blank=True, null=True)
    age = models.IntegerField(blank=True, null=True)
    gender = models.CharField(max_length=50, blank=True, null=True)
    mobile_no = models.CharField(max_length=10, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    history_sheet_no = models.CharField(max_length=100, blank=True, null=True)
    opening_date = models.DateField(blank=True, null=True)
    order_date = models.DateField(blank=True, null=True)
    permanent_address = models.TextField(blank=True, null=True)
    present_address = models.TextField(blank=True, null=True)
    same_as_above = models.BooleanField(default=False)
    native_place = models.CharField(max_length=255, blank=True, null=True)
    occupation = models.CharField(max_length=255, blank=True, null=True)
    aadhaar_id_details = models.CharField(max_length=255, blank=True, null=True)
    categories = SafeArrayField(models.CharField(max_length=100), default=list, blank=True, null=True)
    category_other = models.CharField(max_length=255, blank=True, null=True)
    modus_operandi = models.TextField(blank=True, null=True)
    total_cases = models.IntegerField(blank=True, null=True)
    convicted_cases = models.IntegerField(blank=True, null=True)
    pending_cases = models.IntegerField(blank=True, null=True)
    acquitted_discharged_cases = models.IntegerField(blank=True, null=True)
    whereabouts = models.TextField(blank=True, null=True)
    last_verification_date = models.DateField(blank=True, null=True)
    verification_remarks = models.TextField(blank=True, null=True)
    closure_date = models.DateField(blank=True, null=True)
    closure_reason = models.CharField(max_length=255, blank=True, null=True)
    closure_remarks = models.TextField(blank=True, null=True)
    currently_in_jail = models.CharField(max_length=10, blank=True, null=True)
    currently_on_bail = models.CharField(max_length=10, blank=True, null=True)
    created_by = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'history_sheeters'
        verbose_name = 'History Sheeter'
        verbose_name_plural = 'History Sheeters'
        unique_together = ('station_name', 'sr_no')
        ordering = ['sr_no']

    def __str__(self):
        return f"HS-{self.station_name}/{self.sr_no} ({self.name or '-'})"


class HistorySheeterRelatedPerson(models.Model):
    """
    Repeating person particulars (Associates, Rivals, Sureties) stored in `<schema>.history_sheeter_related_persons`.
    """
    id = models.BigAutoField(primary_key=True)
    history_sheeter = models.ForeignKey(
        HistorySheeter,
        on_delete=models.CASCADE,
        related_name='related_persons',
        db_column='history_sheeter_id'
    )
    person_type = models.CharField(max_length=20)  # 'associate', 'rival', 'surety'
    name = models.CharField(max_length=255, blank=True, null=True)
    alias = models.CharField(max_length=255, blank=True, null=True)
    nickname = models.CharField(max_length=255, blank=True, null=True)
    age = models.IntegerField(blank=True, null=True)
    gender = models.CharField(max_length=50, blank=True, null=True)
    mobile_no = models.CharField(max_length=10, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'history_sheeter_related_persons'
        verbose_name = 'History Sheeter Related Person'
        verbose_name_plural = 'History Sheeter Related Persons'


class HistorySheeterPreventiveAction(models.Model):
    """
    Repeating preventive action record stored in `<schema>.history_sheeter_preventive_actions`.
    """
    id = models.BigAutoField(primary_key=True)
    history_sheeter = models.ForeignKey(
        HistorySheeter,
        on_delete=models.CASCADE,
        related_name='preventive_actions',
        db_column='history_sheeter_id'
    )
    action_type = models.CharField(max_length=100, blank=True, null=True)
    action_other = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'history_sheeter_preventive_actions'
        verbose_name = 'History Sheeter Preventive Action'
        verbose_name_plural = 'History Sheeter Preventive Actions'


class HistorySheeterCrime(models.Model):
    """
    Repeating Crime Chart entry stored in `<schema>.history_sheeter_crimes`.
    """
    id = models.BigAutoField(primary_key=True)
    history_sheeter = models.ForeignKey(
        HistorySheeter,
        on_delete=models.CASCADE,
        related_name='crimes',
        db_column='history_sheeter_id'
    )
    cr_no = models.CharField(max_length=100, blank=True, null=True)
    crime_head = models.TextField(blank=True, null=True)
    act_section = models.TextField(blank=True, null=True)
    # Act / Section / Subsection picked from the Acts master: text copies plus
    # ids WITHOUT foreign keys, so replacing the Acts data never alters a row.
    act_id = models.BigIntegerField(blank=True, null=True)
    section_id = models.BigIntegerField(blank=True, null=True)
    subsection_id = models.BigIntegerField(blank=True, null=True)
    act_name = models.TextField(blank=True, null=True)
    section_number = models.TextField(blank=True, null=True)
    section_title = models.TextField(blank=True, null=True)
    subsection_code = models.TextField(blank=True, null=True)
    register_date = models.DateField(blank=True, null=True)
    police_station = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'history_sheeter_crimes'
        verbose_name = 'History Sheeter Crime'
        verbose_name_plural = 'History Sheeter Crimes'
        ordering = ['-register_date']
