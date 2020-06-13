#
# OpenKM Persistent
#
# Once this image is built, you must upload it as mbagnall/openkm:latest
#
# docker build . -t mbagnall/openkm:latest
# docker push mbagnall/openkm:image
#

FROM mbagnall/openkm:image

COPY run.sh /run.sh
RUN chmod +x /run.sh

VOLUME ["/opt/tomcat-8.5.34/repository"]

CMD ["/run.sh"]