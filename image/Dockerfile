#
# OpenKM Persistent
#
# Once this image is built, you must run it and then commit the container
# as mbagnall/openkm:image
#
# docker build . -t mbagnall/openkm:image
# docker run mbagnall/openkm:image
# docker commit <container id> mbagnall/openkm:image
# docker push mbagnall/openkm:image
#

FROM ubuntu:xenial

LABEL name="OpenKM Base Container"
LABEL maintainer="Michael R. Bagnall <mbagnall@flyingflip.com>"
LABEL vendor="FlyingFlip Studios, LLC."
LABEL version="6.3.9"


RUN apt-get update -y

RUN apt-get update -y && \
  apt-get install -y \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-osd \ 
    openjdk-8-jdk \
    expect \
    coreutils \
    vim

RUN useradd openkm

WORKDIR /opt

COPY OKMInstaller.jar OKMInstaller.jar
COPY expect.exp expect.exp
COPY run.sh run.sh
RUN chmod +x run.sh expect.exp

EXPOSE 8080

CMD [ "./expect.exp" ]

#RUN wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/kea-algorithm/kea-5.0_full.zip
#RUN unzip kea-5.0_full.zip
#RUN export KEAHOME=/root/kea-5.0_full
#RUN export CLASSPATH=$CLASSPATH:$KEAHOME
#RUN export CLASSPATH=$CLASSPATH:$KEAHOME/lib/*.jar