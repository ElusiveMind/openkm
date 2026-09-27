#!/bin/bash
#
# Build-time installer driver. Runs OKMInstaller.jar through expect for the
# selected DATABASE and leaves a ready-to-start Tomcat behind /opt/tomcat.
# Called from the Dockerfile.
#

set -euo pipefail

export OPENKM_VERSION="${OPENKM_VERSION:-6.3.13}"
export DATABASE="${DATABASE:-mysql}"
export DATABASE_HOST="${DATABASE_HOST:-db}"
export DATABASE_NAME="${DATABASE_NAME:-okmdb}"
export DATABASE_USER="${DATABASE_USER:-openkm}"
export DATABASE_PASSWORD="${DATABASE_PASSWORD:-OpenKM77}"

case "$DATABASE" in
  mysql|mariadb|oracle|sqlserver|postgresql)
    ;;
  *)
    # The current OpenKM installer only offers database servers, for 6.3
    # as well as 7.0. The embedded h2 option of the older 6.3 installer
    # is gone.
    echo "Unsupported DATABASE '$DATABASE'." >&2
    echo "Use one of: mysql, mariadb, oracle, sqlserver, postgresql" >&2
    exit 1
    ;;
esac

echo "Installing OpenKM $OPENKM_VERSION with database backend: $DATABASE"

cd /opt
/opt/setup-expect-server.exp

# The 6.3 installer writes the Hibernate settings into OpenKM.cfg and the
# datasource into Tomcat's server.xml.
if [[ ! -f /opt/tomcat/OpenKM.cfg ]]; then
  echo "Installer finished but /opt/tomcat/OpenKM.cfg is missing." >&2
  exit 1
fi

# MySQL 8 authenticates with caching_sha2_password, which Connector/J can
# only complete over TLS or through an RSA public key exchange. The
# installer writes useSSL=false into the datasource URL, which rules out
# TLS, and the key exchange is off unless the URL asks for it, so every
# connection fails with "Public Key Retrieval is not allowed". Turn the key
# exchange on.
if [[ "$DATABASE" == "mysql" ]]; then
  sed -i 's|\(url="jdbc:mysql://[^"]*\)"|\1\&amp;allowPublicKeyRetrieval=true"|' /opt/tomcat/conf/server.xml
  if ! grep -q 'allowPublicKeyRetrieval=true' /opt/tomcat/conf/server.xml; then
    echo "Could not add allowPublicKeyRetrieval=true to the MySQL datasource URL in server.xml." >&2
    exit 1
  fi
  echo "Datasource URL: $(grep -o 'url="jdbc:mysql://[^"]*"' /opt/tomcat/conf/server.xml)"
fi

echo "OpenKM $OPENKM_VERSION installed with database backend: $DATABASE"
