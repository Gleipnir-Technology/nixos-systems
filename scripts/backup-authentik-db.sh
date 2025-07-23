#!/usr/bin/env bash
set -euo pipefail
set -o xtrace

service_redis="podman-authentik-redis"
service_server="podman-authentik-server"
service_worker="podman-authentik-worker"
backup_dir="/var/backups/authentik-db"
backup_file="$backup_dir/authentik-db-$(date +%Y-%m-%d_%H-%M-%S).dump"

# Stop the services
echo "Stopping $service_redis..."
systemctl stop "$service_redis"
echo "Stopping $service_server..."
systemctl stop "$service_server"
#echo "Stopping $service_worker..."
#systemctl stop "$service_worker"

# Ensure backup directory exists
echo "Creating backup directory"
mkdir -p "$backup_dir"

# Perform the database backup (requires appropriate pg_dump credentials)
echo "Backing up database..."
pg_dump -U "$AUTHENTIK_POSTGRESQL__USER" -d "$AUTHENTIK_POSTGRESQL__NAME" -h "$AUTHENTIK_POSTGRESQL__HOST" -p "$AUTHENTIK_POSTGRESQL__PORT" -f "$backup_file"

# Check if the backup was successful
if [ -s "$backup_file" ]; then
  echo "Backup successful: $backup_file"
else
  echo "Backup failed!"
  exit 1 # Indicate an error
fi

# Restart the service
echo "Restarting $service_redis..."
systemctl start "$service_redis"
echo "Restarting $service_server..."
systemctl start "$service_server"
echo "Restarting $service_worker..."
systemctl start "$service_worker"

echo "Backup complete."
