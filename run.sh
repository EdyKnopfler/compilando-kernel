#!/bin/bash
docker run --rm -it \
    -v "`pwd`/kernel/linux-source-4.19:/kernel/linux-source-4.19" \
    compilando-kernel \
    /bin/bash

