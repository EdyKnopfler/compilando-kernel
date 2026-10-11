FROM i386/debian:bookworm

ENV KCFLAGS="-march=pentium-m -O2 -pipe"
ENV KCPPFLAGS="-march=pentium-m -O2 -pipe"
ENV KERNEL_VERSION="6.1"

ADD apt/sources.list /etc/apt/sources.list

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
