#
# OpenKM Persistent
#
# You need to run this once for each base image and upload it for
# it to work. Usually this is done once for each database base image
# and named "base-<databse>",
#
# Once this image is built, you must upload it as mbagnall/openkm:<tag>
#
# Example:
# docker build . -t mbagnall/openkm:mysql
# docker push mbagnall/openkm:mysql
#

FROM mbagnall/openkm:base-mysql

COPY keas.war /root/keas.war
COPY vocabulary-sample.zip /root/vocabulary-sample.zip
COPY keas.properties /root/keas.properties
COPY run.sh /run.sh
RUN chmod +x /run.sh

VOLUME ["/opt/tomcat-8.5.34/repository"]

CMD ["/run.sh"]