#!/bin/bash

if [[ -n "${DATABASE}" ]]; then
  export DATABASE="$DATABASE"
else
  export DATABASE="h2"
fi

if [ $DATABASE = "mysql" ]; then
  if [[ -n "${DATABASE_HOST}" ]]; then
    export DATABASE_HOST="$DATABASE_HOST;"
  else
    export DATABASE_HOST="db"
  fi
  if [[ -n "${DATABASE_NAME}" ]]; then
    export DATABASE_NAME="$DATABASE_NAME;"
  else
    export DATABASE_NAME=""
  fi
  if [[ -n "${DATABASE_USER}" ]]; then
    export DATABASE_USER="$DATABASE_USER;"
  else
    export DATABASE_USER=""
  fi
  if [[ -n "${DATABASE_PASSWORD}" ]]; then
    export DATABASE_PASSWORD="$DATABASE_PASS;"
  else
    export DATABASE_PASSWORD="OpenKM77"
  fi
  envsubst < /opt/setup-expect-mysql.exp > /opt/expect.exp
else
  envsubst < /opt/setup-expect-h2.exp > /opt/expect.exp
fi

chmod +x /opt/expect.exp
/opt/expect.exp
