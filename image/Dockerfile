#
# OpenKM Persistent
#
# Once this image is built, you must run it and then commit the container
# as mbagnall/openkm:image
#
# docker build . -t mbagnall/openkm:image
# docker run mbagnall/openkm:image
#
# Environment Variables
# URL - The URL to OpenKM. Used to set up KEA.
# DATABASE - The database selector. Options are:
#   h2 - default
#   mysql - connection to a MySQL server. Default is to
#     use the one created on the docker container. If using
#     the on-board MySQL server, it is recommended to mount
#     the MySQL directory (/var/lib/mysql) to your file system
#     If not default, must define:
#       DATABASE_HOST - the host name of the database
#       DATABASE_NAME - the name of the database
#       DATABASE_USER - the user to connect to the database
#       DATABASE_PASSWORD - the password for the user specified above.
#   mariadb - same as MySQL
#   oracle
#   sqlserver
#   postgresql
#
# example:
# docker run -e URL=https://example.com -e DATABASE=mysql mbagnall/openkm:mysql
#
# Then you should commit the container if you wish to push to a
# Docker repository such as DockerHub.
#
# docker commit <container id> mbagnall/openkm:image
# docker push mbagnall/openkm:image
#

FROM ubuntu:xenial

LABEL name="OpenKM Base Container"
LABEL maintainer="Michael R. Bagnall <mbagnall@flyingflip.com>"
LABEL vendor="FlyingFlip Studios, LLC."
LABEL version="6.3.9"

RUN export DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
  apt-get -q -y install\
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-osd \ 
    openjdk-8-jdk \
    expect \
    coreutils \
    unzip \
    vim \
    gettext

WORKDIR /opt

RUN useradd openkm

COPY OKMInstaller.jar OKMInstaller.jar
COPY setup-expect-mysql.exp setup-expect-mysql.exp
COPY setup-expect-h2.exp setup-expect-h2.exp
COPY setup.sh setup.sh
COPY run.sh run.sh
RUN chmod +x run.sh setup-expect-mysql.exp setup-expect-h2.exp setup.sh

EXPOSE 8080

CMD [ "./setup.sh" ]
