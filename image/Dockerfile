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
  gettext \
  curl \
  zip

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
# keas.war bundles ICU4J 3.4.4 (pulled in by Jena/IRI for vocabulary
# parsing). That ICU4J cannot parse a Java version whose update number is
# above 255, and Ubuntu 24.04 ships Java 8u504, so KEA crashes at startup.
# Swap in a current ICU4J from Maven Central while copying the war in. The
# Normalizer and IDNA calls that Jena/IRI make are still present in it.
#
ARG ICU4J_VERSION=74.2
ARG ICU4J_SHA256=95c055080e14c093ebeeba5b733e1a1be7a4af5854668c774cedf070d4240e43

RUN --mount=type=bind,source=keas.war,target=/tmp/keas.war \
  cp /tmp/keas.war /root/keas.war && \
  mkdir -p /tmp/icu/WEB-INF/lib && \
  curl -fsSL -o /tmp/icu/WEB-INF/lib/icu4j-${ICU4J_VERSION}.jar \
    "https://repo1.maven.org/maven2/com/ibm/icu/icu4j/${ICU4J_VERSION}/icu4j-${ICU4J_VERSION}.jar" && \
  echo "${ICU4J_SHA256}  /tmp/icu/WEB-INF/lib/icu4j-${ICU4J_VERSION}.jar" | sha256sum -c - && \
  zip -q -d /root/keas.war 'WEB-INF/lib/icu4j-3.4.4.jar' && \
  cd /tmp/icu && zip -q -r /root/keas.war "WEB-INF/lib/icu4j-${ICU4J_VERSION}.jar" && \
  rm -rf /tmp/icu

COPY vocabulary-sample.zip /root/vocabulary-sample.zip
COPY keas.properties /root/keas.properties
COPY run.sh /run.sh
RUN chmod +x /run.sh

VOLUME ["/opt/tomcat-8.5.69/repository"]

EXPOSE 8080

CMD ["/run.sh"]
