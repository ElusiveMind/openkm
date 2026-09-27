#!/bin/bash

TOMCAT=/opt/tomcat

# Existing data in the repository volume means the schema already exists,
# so stop Hibernate from creating it again. OpenKM flips this setting to
# "none" itself after its first start, but that edit lands in the container
# layer, so a fresh container from the image still carries the original
# value. On 6.3 that value is "create", which drops every OpenKM table
# before recreating it, so skipping this step against a populated database
# destroys its contents.
#
# OpenKM 6.3 keeps the flag in OpenKM.cfg, OpenKM 7.0 in openkm.properties.
#
# A first start that failed before the schema was created still leaves the
# datastore directory behind. To retry, remove the repository volume and the
# database together.
if [[ -d "$TOMCAT/repository/datastore" ]]; then
  echo "Existing repository found, skipping schema creation."
  if [[ -f "$TOMCAT/OpenKM.cfg" ]]; then
    sed -i 's/^hibernate\.hbm2ddl=.*/hibernate.hbm2ddl=none/' "$TOMCAT/OpenKM.cfg"
  fi
  if [[ -f "$TOMCAT/openkm.properties" ]]; then
    sed -i 's/^spring\.jpa\.hibernate\.ddl-auto=.*/spring.jpa.hibernate.ddl-auto=none/' "$TOMCAT/openkm.properties"
  fi
else
  echo "Empty repository, OpenKM will create its schema on this start."
fi

# KEA calls OpenKM's REST API from inside this container, so OPEN_KM_URL is
# the local Tomcat port plus the installed context path: /OpenKM on 6.3,
# /openkm on 7.0. OPEN_KM_BASE_URL is the address browsers use to reach
# OpenKM; KEA allows it as a CORS origin, so it carries the published port
# or domain. Before the first start only the war exists; Tomcat unpacks it
# into the directory on that start.
if [[ -e "$TOMCAT/webapps/OpenKM.war" || -d "$TOMCAT/webapps/OpenKM" ]]; then
  OPENKM_CONTEXT=OpenKM
else
  OPENKM_CONTEXT=openkm
fi
export OPEN_KM_URL="${OPEN_KM_URL:-http://localhost:8080/${OPENKM_CONTEXT}}"
export OPEN_KM_BASE_URL="${OPEN_KM_BASE_URL:-http://localhost:8080}"

cp /root/keas.war "$TOMCAT/webapps/keas.war"
cp /root/vocabulary-sample.zip "$TOMCAT/vocabulary-sample.zip"
envsubst < /root/keas.properties > "$TOMCAT/keas.properties"
cd "$TOMCAT"
unzip -o vocabulary-sample.zip > /dev/null 2>&1

"$TOMCAT/bin/startup.sh" > /dev/null 2>&1

# Keep the container in the foreground and surface Tomcat's log.
exec tail -F "$TOMCAT/logs/catalina.out"
