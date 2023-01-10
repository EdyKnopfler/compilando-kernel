FROM i386/debian:bullseye

ENV KCFLAGS="-march=pentium4 -O2 -pipe"
ENV KCPPFLAGS="-march=pentium4 -O2 -pipe"

RUN apt update
RUN apt install -y \
    rsync \
    ca-certificates \
    build-essential \
    linux-source-5.10 \
    bc \
    kmod \
    cpio \
    flex \
    libncurses5-dev \
    libelf-dev \
    libssl-dev \
    dwarves \
    bison

RUN mkdir /kernel
ADD bin /kernel
WORKDIR /kernel

