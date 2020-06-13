#!/bin/bash
FILE="/opt/tomcat-8.5.34/repository/okmdb.mv.db"

if [ -f "$FILE" ];
then
   echo "File $FILE exist. Don't create a DB."
   sed -i 's/hibernate.hbm2ddl=create/hibernate.hbm2ddl=none/g' /opt/tomcat-8.5.34/OpenKM.cfg
else
   echo "File $FILE does not exist. Create a DB."
fi

/etc/init.d/openkm start
tail -f
