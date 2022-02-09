#!/bin/bash


echo "Migration Script - RDS"

echo "Starting migration..."

echo "Database name is only used for authentication purposes"

if [ -z "$DATABASE_NAME" ]; then
    read -p "Database name: " DATABASE_NAME
fi

if [ -z "$DATABASE_USER" ]; then
    read -p "Database user: " DATABASE_USER
fi

if [ -z "$DATABASE_PASSWORD" ]; then
    read -p "Database password: " DATABASE_PASSWORD
fi

if [ -z "$DATABASE_HOST" ]; then
    read -p "Database host: " DATABASE_HOST
fi

echo "Your Inputs: "
echo "Database Name: $DATABASE_NAME"
echo "Database User: $DATABASE_USER"
echo "Database Password: $DATABASE_PASSWORD"
echo "Database Host: $DATABASE_HOST"

read -p "Is this correct? (y/n): " IS_CORRECT

if [ "$IS_CORRECT" != "y" ]; then
    echo "Exiting..."
    exit 1
fi

export PGPASSWORD=$DATABASE_PASSWORD

DATABASE_VERSION=$(psql -h $DATABASE_HOST -U $DATABASE_USER -d $DATABASE_NAME -t -c "SELECT version();" | cut -d " " -f 3 | sed -s 's/\..*//g')

echo "Printing Database Version $DATABASE_VERSION"

echo "Installing dependencies..."

sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

apt-get remove --purge postgresql* -y
apt-get update -y
apt-get install -y postgresql-client-$(echo $DATABASE_VERSION | cut -d ' ' -f 3)


echo "Taking Backup..."

pg_dumpall -h $DATABASE_HOST -U $DATABASE_USER --no-role-passwords -f backup.sql

if [ $? -ne 0 ]; then
    echo "Failed to take backup."
    exit 1
fi


echo "Database Dump Created."

if [ -z "$DEST_DATABASE_NAME" ]; then
    read -p "Database name: " DEST_DATABASE_NAME
fi

if [ -z "$DEST_DATABASE_USER" ]; then
    read -p "Database user: " DEST_DATABASE_USER
fi

if [ -z "$DEST_DATABASE_PASSWORD" ]; then
    read -p "Database password: " DEST_DATABASE_PASSWORD
fi

if [ -z "$DEST_DATABASE_HOST" ]; then
    read -p "Database host: " DEST_DATABASE_HOST
fi


echo "Your Inputs: "
echo "Database Name: $DEST_DATABASE_NAME"
echo "Database User: $DEST_DATABASE_USER"
echo "Database Password: $DEST_DATABASE_PASSWORD"
echo "Database Host: $DEST_DATABASE_HOST"

export PGPASSWORD=$DEST_DATABASE_PASSWORD

read -p "Is this correct? (y/n): " IS_CORRECT

if [ "$IS_CORRECT" != "y" ]; then
    echo "Exiting..."
    exit 1
fi


echo "Restoring Database..."

psql -h $DEST_DATABASE_HOST -U $DEST_DATABASE_USER -d $DEST_DATABASE_NAME < backup.sql

if [ $? -eq 0 ]; then
    echo "Database restored successfully."
else
    echo "Database restore failed."
    exit 1
fi

