#!/bin/bash
KERNEL_VERSION="6.1"
docker run --rm -it \
    -v "`pwd`/kernel/linux-source-$KERNEL_VERSION:/kernel/linux-source-$KERNEL_VERSION" \
    -v "`pwd`:/projeto" \
    compilando-kernel \
    /bin/bash
