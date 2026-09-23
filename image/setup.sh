#!/bin/bash
#
# Build-time installer driver. Runs OKMInstaller.jar through expect for the
# selected DATABASE and leaves a ready-to-start Tomcat behind /opt/tomcat.
# Called from the Dockerfile.
#

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

cd /opt
/opt/setup-expect-server.exp

if [[ ! -f /opt/tomcat/openkm.properties ]]; then
  echo "Installer finished but /opt/tomcat/openkm.properties is missing." >&2
  exit 1
fi

echo "OpenKM $OPENKM_VERSION installed with database backend: $DATABASE"
