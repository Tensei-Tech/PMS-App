#!/usr/bin/env bash
# exit on error
set -o errexit

pip install -r requirements.txt

python manage.py collectstatic --no-input
python manage.py migrate
# Acts / Sections / Subsections from backend/data/acts/*.xlsx (adds only what is missing)
python manage.py import_acts
