#!/bin/bash
cd "/kernel/linux-source-$KERNEL_VERSION"
make -j`nproc` bindeb-pkg

