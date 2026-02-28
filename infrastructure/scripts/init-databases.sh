#!/bin/bash
set -e

echo "Creating OTT Network databases..."

DATABASES=(
    auth_db
    user_db
    content_db
    video_db
    subscription_db
    recommendation_db
    watchlist_db
    notification_db
    analytics_db
    ad_db
    social_db
    tenant_db
)

for db in "${DATABASES[@]}"; do
    echo "Creating database: $db"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        SELECT 'CREATE DATABASE $db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
EOSQL
done

echo "All databases created successfully."
