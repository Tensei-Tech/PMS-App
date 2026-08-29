"""
Django settings for config project.
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment variables from .env file
load_dotenv(BASE_DIR / '.env')

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', 'django-insecure-@51sny-7+youtkld3r$_5qss!ri!)s3is2sa-4y67jzk_^@y^e')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.getenv('DEBUG', 'True') == 'True'

ALLOWED_HOSTS = ['*']


# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Third-Party Apps
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',

    # Local Domain Apps
    'apps.core',
    'apps.public_master',
    'apps.authentication',
    'apps.users',
    'apps.stations',
    'apps.cases',
]

try:
    import dj_database_url
except ImportError:
    dj_database_url = None

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # Top of middleware for CORS
    'apps.core.middleware.TenantMiddleware',
    'django.middleware.security.SecurityMiddleware',
]

try:
    import whitenoise
    MIDDLEWARE.append('whitenoise.middleware.WhiteNoiseMiddleware')
except ImportError:
    pass

MIDDLEWARE.extend([
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
])

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'


# Database Configuration - Primary (Write) + Read Replicas for High Availability
DATABASES = {}

# 1. Primary Database (Writes & Critical Operations)
if os.getenv('DATABASE_URL') and dj_database_url:
    DATABASES['default'] = dj_database_url.config(
        default=os.getenv('DATABASE_URL'),
        conn_max_age=600,
        conn_health_checks=True,
        ssl_require=True,
    )
elif os.getenv('DB_NAME') and os.getenv('DB_PASSWORD') and os.getenv('DB_PASSWORD') != 'YOUR_SUPABASE_DB_PASSWORD':
    DATABASES['default'] = {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'postgres'),
        'USER': os.getenv('DB_USER', 'postgres'),
        'PASSWORD': os.getenv('DB_PASSWORD', ''),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '5432'),
        'CONN_MAX_AGE': 600,
        'CONN_HEALTH_CHECKS': True,
        'OPTIONS': {
            'sslmode': os.getenv('DB_SSLMODE', 'require'),
        },
    }
else:
    DATABASES['default'] = {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }

# 2. Read Replica 1 (Optional - High Load Read Offloading)
if os.getenv('DATABASE_REPLICA_1_URL') and dj_database_url:
    DATABASES['replica_1'] = dj_database_url.config(
        default=os.getenv('DATABASE_REPLICA_1_URL'),
        conn_max_age=600,
        conn_health_checks=True,
        ssl_require=True,
    )
elif os.getenv('DB_REPLICA_1_HOST'):
    DATABASES['replica_1'] = {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_REPLICA_1_NAME', os.getenv('DB_NAME', 'postgres')),
        'USER': os.getenv('DB_REPLICA_1_USER', os.getenv('DB_USER', 'postgres')),
        'PASSWORD': os.getenv('DB_REPLICA_1_PASSWORD', os.getenv('DB_PASSWORD', '')),
        'HOST': os.getenv('DB_REPLICA_1_HOST'),
        'PORT': os.getenv('DB_REPLICA_1_PORT', '5432'),
        'CONN_MAX_AGE': 600,
        'CONN_HEALTH_CHECKS': True,
        'OPTIONS': {
            'sslmode': os.getenv('DB_SSLMODE', 'require'),
        },
    }

# 3. Read Replica 2 (Optional - High Load Read Offloading)
if os.getenv('DATABASE_REPLICA_2_URL') and dj_database_url:
    DATABASES['replica_2'] = dj_database_url.config(
        default=os.getenv('DATABASE_REPLICA_2_URL'),
        conn_max_age=600,
        conn_health_checks=True,
        ssl_require=True,
    )
elif os.getenv('DB_REPLICA_2_HOST'):
    DATABASES['replica_2'] = {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_REPLICA_2_NAME', os.getenv('DB_NAME', 'postgres')),
        'USER': os.getenv('DB_REPLICA_2_USER', os.getenv('DB_USER', 'postgres')),
        'PASSWORD': os.getenv('DB_REPLICA_2_PASSWORD', os.getenv('DB_PASSWORD', '')),
        'HOST': os.getenv('DB_REPLICA_2_HOST'),
        'PORT': os.getenv('DB_REPLICA_2_PORT', '5432'),
        'CONN_MAX_AGE': 600,
        'CONN_HEALTH_CHECKS': True,
        'OPTIONS': {
            'sslmode': os.getenv('DB_SSLMODE', 'require'),
        },
    }

# High-Availability Database Router (Primary Writes, Replica Reads)
DATABASE_ROUTERS = ['apps.core.db_router.PrimaryReplicaRouter']
DB_NATIVE_REPLICATION = os.getenv('DB_NATIVE_REPLICATION', 'False').lower() == 'true'


# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True


# Static files (CSS, JavaScript, Images)
STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'


# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'


# CORS Settings (Allow mobile app and web frontend)
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True


from datetime import timedelta

# REST Framework Settings
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'apps.authentication.authentication.PrimaryJWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
}

# SimpleJWT Settings
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=30),
    'ROTATE_REFRESH_TOKENS': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

# ------------------------------------------------------------------------------
# SECURITY & TLS IN TRANSIT CONFIGURATION
# ------------------------------------------------------------------------------
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_SSL_REDIRECT = os.getenv('SECURE_SSL_REDIRECT', 'False').lower() == 'true'
SESSION_COOKIE_SECURE = os.getenv('SESSION_COOKIE_SECURE', 'False').lower() == 'true'
CSRF_COOKIE_SECURE = os.getenv('CSRF_COOKIE_SECURE', 'False').lower() == 'true'
SECURE_HSTS_SECONDS = 31536000 if not DEBUG else 0
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# ------------------------------------------------------------------------------
# UPSTASH REDIS CACHE LAYER CONFIGURATION
# ------------------------------------------------------------------------------
UPSTASH_REDIS_REST_URL = os.getenv('UPSTASH_REDIS_REST_URL', 'https://mature-eel-202638.upstash.io')
UPSTASH_REDIS_REST_TOKEN = os.getenv('UPSTASH_REDIS_REST_TOKEN', 'ggAAAAAAAxeOAAIgcDHNa0zn2Xyy2gpsLIRRDdqRI68u7SlPuCjzaUUXePSvkA')
REDIS_URL = os.getenv('REDIS_URL', 'rediss://default:ggAAAAAAAxeOAAIgcDHNa0zn2Xyy2gpsLIRRDdqRI68u7SlPuCjzaUUXePSvkA@mature-eel-202638.upstash.io:6379')

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'pms-app-cache-layer',
        'TIMEOUT': 300,  # Default 5 min TTL
    }
}



