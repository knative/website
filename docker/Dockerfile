FROM ubuntu:18.04

RUN apt-get update -y && apt-get install git wget -y

RUN wget https://github.com/gohugoio/hugo/releases/download/v0.81.0/hugo_extended_0.81.0_Linux-64bit.deb
RUN dpkg -i hugo_extended_0.81.0_Linux-64bit.deb

RUN git clone --recurse-submodules https://github.com/knative/website.git
RUN git clone https://github.com/knative/docs.git

WORKDIR /website

COPY scripts.patch .
RUN patch -p0 < scripts.patch

ENTRYPOINT ["/bin/bash", "scripts/localbuild.sh","-s","reload"]

EXPOSE 1313
