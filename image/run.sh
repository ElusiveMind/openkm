#!/bin/bash
#
# Runtime entrypoint. Deploys KEA next to OpenKM and starts Tomcat.
#

TOMCAT=/opt/tomcat

# Existing data in the repository volume means the schema already exists,
# so stop Hibernate from creating it again. OpenKM flips this setting to
# "none" itself after a successful first start, but a fresh container from
# the image still carries the original "create-only".
if [[ -d "$TOMCAT/repository/datastore" ]]; then
  echo "Existing repository found, skipping schema creation."
  sed -i 's/^spring\.jpa\.hibernate\.ddl-auto=.*/spring.jpa.hibernate.ddl-auto=none/' "$TOMCAT/openkm.properties"
else
  echo "Empty repository, OpenKM will create its schema on this start."
fi

export OPEN_KM_URL="${OPEN_KM_URL:-http://localhost:8080/openkm}"
export OPEN_KM_BASE_URL="${OPEN_KM_BASE_URL:-http://localhost:8080}"

cp /root/keas.war "$TOMCAT/webapps/keas.war"
cp /root/vocabulary-sample.zip "$TOMCAT/vocabulary-sample.zip"
envsubst < /root/keas.properties > "$TOMCAT/keas.properties"
cd "$TOMCAT"
unzip -o vocabulary-sample.zip > /dev/null 2>&1

"$TOMCAT/bin/startup.sh" > /dev/null 2>&1

# Keep the container in the foreground and surface Tomcat's log.
exec tail -F "$TOMCAT/logs/catalina.out"
