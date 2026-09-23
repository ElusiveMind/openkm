#
# OpenKM Persistent
#
# Single-step build. The OpenKM installer runs during the build, then the
# KEA keyword extraction service and the runtime entrypoint are layered on
# top, so the resulting image is ready to push and run.
#
# Pick the database backend with the DATABASE build argument:
#
#   docker build . -t mbagnall/openkm:h2
#   docker build . --build-arg DATABASE=mysql -t mbagnall/openkm:mysql
#   docker push mbagnall/openkm:mysql
#
# Build arguments
#   DATABASE - The database selector. Options are:
#     h2 - default, embedded database stored in the repository volume
#     mysql
#     mariadb
#     oracle
#     sqlserver
#     postgresql
#
#   For everything except h2 the connection details are written into the
#   image at build time by the installer:
#     DATABASE_HOST     - host name of the database server (default: db)
#     DATABASE_NAME     - database name, or SID for oracle (default: okmdb)
#     DATABASE_USER     - user to connect as (default: openkm)
#     DATABASE_PASSWORD - password for that user (default: OpenKM77)
#
# The installer downloads OpenKM from update.openkm.com, so the build
# needs network access.
#

FROM ubuntu:24.04

LABEL name="OpenKM Persistent"
LABEL maintainer="Michael R. Bagnall <hello@flyingflip.com>"
LABEL vendor="FlyingFlip Studios, LLC."
LABEL version="6.3.12"

# The package lists are kept on purpose: the OpenKM installer runs apt-get
# itself to add libreoffice, imagemagick, xvfb and friends.
RUN apt-get -y update && \
  apt-get -q -y install \
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

#
# Step 1: run the OpenKM installer against the selected database.
#
ARG DATABASE=h2
ARG DATABASE_HOST=db
ARG DATABASE_NAME=okmdb
ARG DATABASE_USER=openkm
ARG DATABASE_PASSWORD=OpenKM77
ENV DATABASE=${DATABASE}

COPY OKMInstaller.jar setup.sh setup-expect-h2.exp setup-expect-server.exp /opt/
RUN chmod +x /opt/setup.sh /opt/setup-expect-h2.exp /opt/setup-expect-server.exp && \
  /opt/setup.sh

#
# Step 2: add KEA and the runtime entrypoint.
#
COPY keas.war /root/keas.war
COPY vocabulary-sample.zip /root/vocabulary-sample.zip
COPY keas.properties /root/keas.properties
COPY run.sh /run.sh
RUN chmod +x /run.sh

VOLUME ["/opt/tomcat-8.5.69/repository"]

EXPOSE 8080

CMD ["/run.sh"]
