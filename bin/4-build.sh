#!/bin/bash
cd /kernel/linux-source-5.10
make -j`nproc` bindeb-pkg

