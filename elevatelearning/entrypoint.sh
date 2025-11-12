#!/bin/bash

# Wait for MySQL to be ready
echo "Waiting for MySQL..."
DB_HOST=${DB_HOST:-db}
while ! nc -z $DB_HOST 3306; do
    sleep 1
done
echo "MySQL is ready!"

# Run migrations
echo "Running database migrations..."
python manage.py makemigrations
python manage.py migrate

# Create superuser if it doesn't exist
echo "Creating superuser..."
python manage.py shell << END
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('Superuser created.')
else:
    print('Superuser already exists.')
END

# Start Gunicorn
echo "Starting Gunicorn..."
exec gunicorn elevatelearning.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 3 \
    --timeout 120 \
    --access-logfile - \
    --error-logfile -
