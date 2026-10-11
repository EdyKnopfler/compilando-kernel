#!/bin/bash
cd "/kernel/linux-source-$KERNEL_VERSION"
export TAR_OPTIONS=--no-same-owner
make -j`nproc` bindeb-pkg
