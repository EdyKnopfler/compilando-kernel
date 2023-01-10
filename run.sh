#!/bin/bash
docker run --rm -it \
    -v "`pwd`/kernel/linux-source-5.10:/kernel/linux-source-5.10" \
    compilando-kernel \
    /bin/bash

