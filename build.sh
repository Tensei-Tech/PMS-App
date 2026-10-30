#!/usr/bin/env bash
# exit on error
set -o errexit

cd backend
pip install -r requirements.txt

python manage.py collectstatic --no-input

# The shared Supabase pooler allows a fixed number of clients (pool_size). When
# the live app and others hold them all, migrate fails with "max clients
# reached" before it starts; that clears in seconds, so wait and try again.
# Any other error still fails the build at once.
attempt=1
until output=$(python manage.py migrate 2>&1); do
  echo "$output"
  if ! echo "$output" | grep -qiE "max clients reached|too many clients|EMAXCONNSESSION"; then
    exit 1
  fi
  if [ "$attempt" -ge 5 ]; then
    echo "Database still has no free connection after $attempt attempts."
    exit 1
  fi
  echo "Database connections are all in use; retrying migrate in 15 s (attempt $attempt of 5)..."
  attempt=$((attempt + 1))
  sleep 15
done
echo "$output"
