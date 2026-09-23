#!/bin/bash
#
# Build-time installer driver. Runs OKMInstaller.jar through the expect
# script that matches the selected DATABASE. Called from the Dockerfile.
#

set -euo pipefail

export DATABASE="${DATABASE:-h2}"

case "$DATABASE" in
  h2)
    EXPECT_SCRIPT=/opt/setup-expect-h2.exp
    ;;
  mysql|mariadb|oracle|sqlserver|postgresql)
    export DATABASE_HOST="${DATABASE_HOST:-db}"
    export DATABASE_NAME="${DATABASE_NAME:-okmdb}"
    export DATABASE_USER="${DATABASE_USER:-openkm}"
    export DATABASE_PASSWORD="${DATABASE_PASSWORD:-OpenKM77}"
    EXPECT_SCRIPT=/opt/setup-expect-server.exp
    ;;
  *)
    echo "Unsupported DATABASE '$DATABASE'." >&2
    echo "Use one of: h2, mysql, mariadb, oracle, sqlserver, postgresql" >&2
    exit 1
    ;;
esac

echo "Installing OpenKM with database backend: $DATABASE"

cd /opt
"$EXPECT_SCRIPT"

if [[ ! -f /opt/tomcat-8.5.69/OpenKM.cfg ]]; then
  echo "Installer finished but /opt/tomcat-8.5.69/OpenKM.cfg is missing." >&2
  exit 1
fi

echo "OpenKM installed with database backend: $DATABASE"
