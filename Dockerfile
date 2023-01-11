FROM i386/debian:bullseye

ENV KCFLAGS="-march=pentium4 -O2 -pipe"
ENV KCPPFLAGS="-march=pentium4 -O2 -pipe"
ENV KERNEL_VERSION="4.19"

ADD apt/sources.list /etc/apt/sources.list
ADD apt/buster.list /etc/apt/sources.list.d/buster.list 

RUN apt update
RUN apt install -y \
    rsync \
    ca-certificates \
    build-essential \
    linux-source-${KERNEL_VERSION} \
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

