#!/bin/bash
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g. sudo bash enable_remote_postgres.sh)"
  exit 1
fi

PG_DATA="/var/lib/postgres/data"
PG_CONF="$PG_DATA/postgresql.conf"
HBA_CONF="$PG_DATA/pg_hba.conf"

echo "Checking for PostgreSQL data directory at $PG_DATA..."
if [ ! -d "$PG_DATA" ]; then
    echo "Error: Data directory not found at $PG_DATA"
    exit 1
fi

echo "Backing up configuration files..."
cp "$PG_CONF" "$PG_CONF.bak_$(date +%s)"
cp "$HBA_CONF" "$HBA_CONF.bak_$(date +%s)"

echo "Configuring postgresql.conf to listen on all addresses..."
# Uncomment or update listen_addresses
if grep -q "^listen_addresses" "$PG_CONF"; then
    sed -i "s/^listen_addresses.*/listen_addresses = '*'/" "$PG_CONF"
elif grep -q "^#listen_addresses" "$PG_CONF"; then
    sed -i "s/^#listen_addresses.*/listen_addresses = '*'/" "$PG_CONF"
else
    echo "listen_addresses = '*'" >> "$PG_CONF"
fi

echo "Configuring pg_hba.conf to allow remote connections..."
# Check if the line already exists to avoid duplication
if ! grep -q "0.0.0.0/0" "$HBA_CONF"; then
    echo "# Allow remote connections from any IP (Added by script)" >> "$HBA_CONF"
    echo "host    all             all             0.0.0.0/0               scram-sha-256" >> "$HBA_CONF"
fi

echo "Restarting PostgreSQL service..."
systemctl restart postgresql

echo "Updating Firewall (UFW) rules..."
ufw allow 5432/tcp

echo "--------------------------------------------------------"
echo "✅ Remote access configuration completed."
echo "IMPORTANT: You must ensure the 'postgres' user (or other users) has a password set to connect remotely."
echo "To set a password for the 'postgres' user, run:"
echo "   sudo -u postgres psql -c \"\\password postgres\""
echo "--------------------------------------------------------"
