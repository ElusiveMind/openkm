#
# OpenKM Persistent
#
# Once this image is built, you must run it and then commit the container
# as mbagnall/openkm:image
#
# docker build . -t mbagnall/openkm:image
# docker run mbagnall/openkm:image
#
#   docker build . -t mbagnall/openkm:mysql
#   docker build . --build-arg DATABASE=postgresql -t mbagnall/openkm:postgresql
#   docker push mbagnall/openkm:mysql
#   docker buildx build --platform linux/amd64,linux/arm64 \
#     --build-arg DATABASE=mysql \
#     --build-arg OPENKM_VERSION=6.3.13 \
#     -t mbagnall/openkm:6.3.13-mysql \
#     --push .
#
# Example with tag:
# docker run --env-file ./env.list mbagnall/openkm:image
# docker run mbagnall/openkm
#
# Then you should commit the container if you wish to push to a
# Docker repository such as DockerHub. An example of which is
#
# docker commit <container id> mbagnall/openkm:<tag>
# docker push mbagnall/openkm:<tag>
#

FROM ubuntu:24.04

ARG OPENKM_VERSION=6.3.13

LABEL name="OpenKM"
LABEL maintainer="Michael R. Bagnall <hello@flyingflip.com>"
LABEL vendor="FlyingFlip Studios, LLC."
LABEL version="${OPENKM_VERSION}"

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
