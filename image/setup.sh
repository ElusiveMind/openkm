#!/bin/bash

set -euo pipefail

export OPENKM_VERSION="${OPENKM_VERSION:-7.0.3}"
export DATABASE="${DATABASE:-mysql}"
export DATABASE_HOST="${DATABASE_HOST:-db}"
export DATABASE_NAME="${DATABASE_NAME:-okmdb}"
export DATABASE_USER="${DATABASE_USER:-openkm}"
export DATABASE_PASSWORD="${DATABASE_PASSWORD:-OpenKM77}"

case "$DATABASE" in
  mysql|mariadb|oracle|sqlserver|postgresql)
    ;;
  *)
    # OpenKM 7.0 needs a database server. The embedded h2 option from the
    # 6.3 images is gone: the 7.0 installer does not offer it, and OpenKM
    # 7.0.3 fails to initialize its schema on H2 even when configured by hand.
    echo "Unsupported DATABASE '$DATABASE'." >&2
    echo "Use one of: mysql, mariadb, oracle, sqlserver, postgresql" >&2
    exit 1
    ;;
esac

echo "Installing OpenKM $OPENKM_VERSION with database backend: $DATABASE"

# MySQL 8 authenticates with caching_sha2_password, which Connector/J can
# only complete over TLS or through an RSA public key exchange. The 6.3
# installer writes useSSL=false into the datasource URL, which rules out
# TLS, and the key exchange is off unless the URL asks for it, so every
# connection fails with "Public Key Retrieval is not allowed". Turn the key
# exchange on. The 6.3 installer keeps the URL in Tomcat's server.xml and
# the 7.0 installer in openkm.properties; patch whichever one has it.
if [[ "$DATABASE" == "mysql" ]]; then
  if [[ -f /opt/tomcat/conf/server.xml ]] && grep -q 'jdbc:mysql://' /opt/tomcat/conf/server.xml; then
    sed -i 's|\(url="jdbc:mysql://[^"]*\)"|\1\&amp;allowPublicKeyRetrieval=true"|' /opt/tomcat/conf/server.xml
  fi
  if [[ -f /opt/tomcat/openkm.properties ]]; then
    sed -i 's|^\(spring\.datasource\.url=jdbc:mysql://.*\)$|\1\&allowPublicKeyRetrieval=true|' /opt/tomcat/openkm.properties
  fi
  if ! grep -q 'allowPublicKeyRetrieval=true' /opt/tomcat/conf/server.xml /opt/tomcat/openkm.properties 2>/dev/null; then
    echo "Could not add allowPublicKeyRetrieval=true to the MySQL datasource URL." >&2
    exit 1
  fi
fi

if [ $DATABASE = "mysql" ]; then
  if [[ -n "${DATABASE_HOST}" ]]; then
    export DATABASE_HOST="$DATABASE_HOST"
  else
    export DATABASE_HOST="db"
  fi
  if [[ -n "${DATABASE_NAME}" ]]; then
    export DATABASE_NAME="$DATABASE_NAME"
  else
    export DATABASE_NAME=""
  fi
  if [[ -n "${DATABASE_USER}" ]]; then
    export DATABASE_USER="$DATABASE_USER"
  else
    export DATABASE_USER=""
  fi
  if [[ -n "${DATABASE_PASSWORD}" ]]; then
    export DATABASE_PASSWORD="$DATABASE_PASS"
  else
    export DATABASE_PASSWORD="OpenKM77"
  fi
  envsubst < /opt/setup-expect-mysql.exp > /opt/expect.exp
else
  envsubst < /opt/setup-expect-h2.exp > /opt/expect.exp
fi

chmod +x /opt/expect.exp
/opt/expect.exp
