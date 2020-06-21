#
# OpenKM Persistent
#
# Once this image is built, you must run it and then commit the container
# as mbagnall/openkm:image
#
# docker build . -t mbagnall/openkm:image
# docker run mbagnall/openkm:image
#
# Environment Variable
# DATABASE - The database selector. Options are:
#   h2 - default
#   mysql - Connection details to a MySQL server. Must define:
#       DATABASE_HOST - the host name of the database
#       DATABASE_NAME - the name of the database
#       DATABASE_USER - the user to connect to the database
#       DATABASE_PASSWORD - the password for the user specified above.
#   mariadb - Same as MySQL
#   oracle
#   sqlserver
#   postgresql
#
# Example with tag:
# docker run -e DATABASE=mysql mbagnall/openkm
# docker run mbagnall/openkm
#
# Then you should commit the container if you wish to push to a
# Docker repository such as DockerHub. An example of which is
#
# docker commit <container id> mbagnall/openkm:<tag>
# docker push mbagnall/openkm:<tag>
#

FROM ubuntu:xenial

LABEL name="OpenKM Base Container"
LABEL maintainer="Michael R. Bagnall <mbagnall@flyingflip.com>"
LABEL vendor="FlyingFlip Studios, LLC."
LABEL version="6.3.9"

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
