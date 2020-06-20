#!/bin/bash
FILE="/opt/tomcat-8.5.34/repository/okmdb.mv.db"
DB="/opt/tomcat-8.5.34/repository/datastore"

if [[ -f "$FILE" || -d "$DB" ]];
then
   echo "No setup required."
   sed -i 's/hibernate.hbm2ddl=create/hibernate.hbm2ddl=none/g' /opt/tomcat-8.5.34/OpenKM.cfg
else
   echo "Begin setup."
fi

cp /root/keas.war /opt/tomcat-8.5.34/webapps/keas.war
cp /root/vocabulary-sample.zip /opt/tomcat-8.5.34/vocabulary-sample.zip
envsubst < /root/keas.properties > /opt/tomcat-8.5.34/keas.properties
cd /opt/tomcat-8.5.34
unzip vocabulary-sample.zip > /dev/null 2&>1

cd /opt/tomcat-8.5.34/bin
./startup.sh > /dev/null 2&>1

tail -f