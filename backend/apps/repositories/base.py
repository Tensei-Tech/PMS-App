from typing import Type, TypeVar, Generic, List, Optional
from django.db import models

T = TypeVar('T', bound=models.Model)


class BaseRepository(Generic[T]):
    """
    Generic Base Repository encapsulating common Django ORM operations.
    """
    def __init__(self, model: Type[T]):
        self.model = model

    def get_by_id(self, id_val) -> Optional[T]:
        """Fetch a single record by primary key."""
        try:
            return self.model.objects.get(pk=id_val)
        except self.model.DoesNotExist:
            return None

    def filter(self, **kwargs) -> models.QuerySet[T]:
        """Filter records matching keyword arguments."""
        return self.model.objects.filter(**kwargs)

    def get_all(self) -> models.QuerySet[T]:
        """Fetch all records."""
        return self.model.objects.all()

    def create(self, **fields) -> T:
        """Create and save a new record."""
        return self.model.objects.create(**fields)

    def update(self, instance: T, **fields) -> T:
        """Update fields on an existing record instance."""
        for key, value in fields.items():
            setattr(instance, key, value)
        instance.save()
        return instance

    def delete(self, instance: T) -> bool:
        """Delete a record instance."""
        instance.delete()
        return True
