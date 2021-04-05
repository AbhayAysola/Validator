#!/bin/sh
set -e

echo "Waiting for postgres..."
until nc -z $POSTGRES_HOST 5432 > /dev/null 2>&1; do
  sleep 1
done
echo "PostgreSQL started"

init_node() {
  selfconfiguration=$(PGPASSWORD=$POSTGRES_PASSWORD psql -X -A \
    -h "$POSTGRES_HOST" -U "$POSTGRES_USER" "$POSTGRES_DB" -t -c \
    "SELECT COUNT(*) from self_configurations_selfconfiguration")

  if [ "$selfconfiguration" = "0" ]; then
    echo "No configuration. Initializing primary validator"

    /opt/project/manage.py initialize_validator \
      --node_identifier "$NODE_IDENTIFIER" \
      --account_number "$ACCOUNT_NUMBER" \
      --default_transaction_fee 1 \
      --daily_confirmation_rate 1 \
      --node_type PRIMARY_VALIDATOR \
      --protocol http \
      --ip_address "$PUBLIC_IP_ADDRESS" \
      --port "$NODE_PORT" \
      --root_account_file https://gist.githubusercontent.com/AbhayAysola/d5c7f594ccd3cfa515e607ecead90c22/raw/e568ecd1ef62a4390faa9dcdc31cd37251a22167/root-account-file.json \
      --version_number v1.0 \
      --unattended

    echo "Primary validator initialized"
  fi
}

if [ "$1" = "" ]; then
  /opt/project/manage.py migrate;
  init_node &
  /opt/project/manage.py runserver 0.0.0.0:8000;
else
  exec "$@"
fi
