#!/bin/bash
FILE="/opt/tomcat-8.5.34/repository/okmdb.mv.db"

if [ -f "$FILE" ];
then
   echo "File $FILE exist. No setup required."
   sed -i 's/hibernate.hbm2ddl=create/hibernate.hbm2ddl=none/g' /opt/tomcat-8.5.34/OpenKM.cfg
else
   echo "File $FILE does not exist. Begin setup."
fi

cp /root/keas.war /opt/tomcat-8.5.34/webapps/keas.war
cp /root/vocabulary-sample.zip /opt/tomcat-8.5.34/vocabulary-sample.zip
cp /root/keas.properties /opt/tomcat-8.5.34/keas.properties
cd /opt/tomcat-8.5.34
unzip vocabulary-sample.zip

cd /opt/tomcat-8.5.34/bin
./startup.sh

tail -f