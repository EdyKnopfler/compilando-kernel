#!/bin/bash
cp $1 "/kernel/linux-source-$KERNEL_VERSION/.config"
sed \
    -i 's/CONFIG_SYSTEM_TRUSTED_KEYS=".*"/CONFIG_SYSTEM_TRUSTED_KEYS=""/' \
    "/kernel/linux-source-$KERNEL_VERSION/.config"

