"""
Short-lived cache for display settings that the reminder endpoints read on
every dashboard open but that almost never change: reminder labels, days and
templates, and the yes/no option value.

Each lookup costs a round trip to Supabase (about 65 ms). Entries live for TTL
seconds; any save or delete of ModuleSetting or OptionValue bumps a version
number, so every cached entry is dropped at once. Changes made with a bulk
queryset.update() or directly in the database skip signals and show up
within TTL seconds.

Never use this for permission checks (enforce_permissions, role permissions):
those must be read live, because a change made directly in the database would
otherwise be ignored for up to TTL seconds.

Keys include the tenant schema wherever the data is per state.
"""
from django.core.cache import cache
from django.db.models.signals import post_delete, post_save

TTL = 60
_VERSION_KEY = 'crimetab_settings_cache_version'
_MISS = object()


def _version():
    version = cache.get(_VERSION_KEY)
    if version is None:
        version = 1
        cache.set(_VERSION_KEY, version, None)
    return version


def invalidate(**_kwargs):
    """Drop every cached entry (signal receiver)."""
    try:
        cache.incr(_VERSION_KEY)
    except ValueError:
        cache.set(_VERSION_KEY, 2, None)


def cached(parts, compute):
    """Value for key `parts` (a tuple), computed with compute() on a miss."""
    key = 'crimetab_settings:%s:%s' % (_version(), ':'.join(str(p) for p in parts))
    value = cache.get(key, _MISS)
    if value is _MISS:
        value = compute()
        cache.set(key, value, TTL)
    return value


def _connect():
    from apps.crimetab.models import ModuleSetting, OptionValue
    for model in (ModuleSetting, OptionValue):
        post_save.connect(invalidate, sender=model, dispatch_uid=f'settings_cache_save_{model.__name__}')
        post_delete.connect(invalidate, sender=model, dispatch_uid=f'settings_cache_delete_{model.__name__}')


_connect()
