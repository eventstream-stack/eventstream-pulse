#!/bin/bash
set -e

# Wait for database
echo "Waiting for database..."
while ! python -c "import psycopg2; psycopg2.connect(host='$POSTGRES_HOST', port='$POSTGRES_PORT', dbname='$POSTGRES_DB', user='$POSTGRES_USER', password='$POSTGRES_PASSWORD')" 2>/dev/null; do
    sleep 1
done
echo "Database is ready!"

# Run migrations
echo "Running migrations..."
python manage.py migrate --noinput

# Start server
echo "Starting server..."
exec gunicorn --bind 0.0.0.0:8000 pulse_admin.wsgi:application --workers 3
