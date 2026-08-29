import random
import logging
from django.db import connections
from django.db.utils import OperationalError

logger = logging.getLogger(__name__)


class PrimaryReplicaRouter:
    """
    High-Availability & High-Load Database Router for Django with Failover Protection.
    
    1. WRITE Operations (INSERT, UPDATE, DELETE):
       - Target 'default' (Primary DB).
       - Failover: If 'default' is down, automatically failover to 'replica_1' (if configured).

    2. READ Operations (SELECT):
       - Load-balanced across active Read Replicas ('replica_1', 'replica_2').
       - Failover: If a replica fails, automatically fallback to 'default'.

    3. Migrations:
       - Restricted exclusively to 'default' (Primary DB).
    """

    def _is_db_healthy(self, db_alias):
        """Check if a database alias is reachable and responding."""
        try:
            conn = connections[db_alias]
            conn.ensure_connection()
            return True
        except (OperationalError, Exception) as e:
            logger.error(f"[DBRouter] Database '{db_alias}' health check failed: {e}")
            return False

    def db_for_read(self, model, **hints):
        """Randomly select a healthy read replica. Fallback to 'default' if replicas fail."""
        from django.conf import settings
        
        if 'instance' in hints and hasattr(hints['instance'], '_state') and hints['instance']._state.db:
            target_db = hints['instance']._state.db
            if target_db in settings.DATABASES and self._is_db_healthy(target_db):
                return target_db

        replicas = [db for db in ['replica_1', 'replica_2'] if db in settings.DATABASES]
        random.shuffle(replicas)

        # Find first healthy replica
        for replica in replicas:
            if self._is_db_healthy(replica):
                return replica

        # Fallback to primary default DB
        return 'default'

    def db_for_write(self, model, **hints):
        """Target primary 'default' DB for writes. Failover to 'replica_1' if 'default' fails."""
        from django.conf import settings
        
        if self._is_db_healthy('default'):
            return 'default'

        # Failover mode: If primary DB is down, route write to replica_1 if available
        if 'replica_1' in settings.DATABASES and self._is_db_healthy('replica_1'):
            logger.warning("[DBRouter] FAILOVER TRIGGERED: Primary 'default' DB is DOWN. Routing WRITE to 'replica_1'.")
            return 'replica_1'

        return 'default'

    def allow_relation(self, obj1, obj2, **hints):
        """Allow foreign key relations across databases."""
        return True

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        """Allow migrations on configured active databases ('default', 'replica_1', 'replica_2')."""
        from django.conf import settings
        return db in settings.DATABASES
