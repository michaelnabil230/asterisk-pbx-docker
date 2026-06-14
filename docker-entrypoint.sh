#!/bin/bash
set -e

DB_URL="${DATABASE_URL}"

cd /usr/src/asterisk-${ASTERISK_VERSION}/contrib/ast-db-manage

# Generate configs if missing

cp -n cdr.ini.sample cdr.ini
cp -n queue_log.ini.sample queue_log.ini
cp -n voicemail.ini.sample voicemail.ini
cp -n config.ini.sample config.ini

# Update DB URL

sed -i "s#mysql://user:pass@localhost/cdr#${DB_URL}#g" cdr.ini
sed -i "s#mysql://user:pass@localhost/queue_log#${DB_URL}#g" queue_log.ini
sed -i "s#mysql://user:pass@localhost/voicemail#${DB_URL}#g" voicemail.ini
sed -i "s#sqlalchemy.url *=.*#sqlalchemy.url = ${DB_URL}#g" config.ini

echo "Running Asterisk DB migrations..."

alembic -c config.ini upgrade head
alembic -c cdr.ini upgrade head
alembic -c queue_log.ini upgrade head
alembic -c voicemail.ini upgrade head

echo "Migrations completed."

exec /usr/sbin/asterisk -vvvdddf -W -U asterisk -p

rm -rf /usr/src/asterisk-${ASTERISK_VERSION}