#!/bin/bash
# Uso: ./3-tune-config.sh <saída do lsmod da máquina alvo>
set -e
cd "/kernel/linux-source-$KERNEL_VERSION"

# Completa opções que a config da distro não tem, para o localmodconfig não perguntar
make olddefconfig

# Mantém só os módulos que a máquina alvo carrega.
# Cópia sem permissão de execução: se o arquivo for executável (vindo de
# pendrive FAT, por exemplo), o localmodconfig o executa em vez de lê-lo.
cp "$1" /tmp/lsmod.txt
chmod -x /tmp/lsmod.txt
yes "" | make LSMOD=/tmp/lsmod.txt localmodconfig    # novas perguntas: aceita o padrão

scripts/config \
    `# Processador: Celeron M (Dothan), núcleo único, sem virtualização` \
    -d MGEODE_LX -e MPENTIUMM \
    -d SMP \
    -d HYPERVISOR_GUEST \
    `# Sem mitigações de Spectre/Meltdown (equivale a mitigations=off)` \
    -d CPU_MITIGATIONS -d RETPOLINE \
    `# Desktop com baixa latência` \
    -d PREEMPT_VOLUNTARY -e PREEMPT -d PREEMPT_DYNAMIC \
    -d HZ_250 -e HZ_1000 \
    `# Memória: HIGHMEM4G e VMSPLIT_3G da distro (NOHIGHMEM + VMSPLIT_2G_OPT deu travamentos)` \
    `# MGLRU ligado, zram` \
    -e LRU_GEN_ENABLED \
    -m ZRAM -m CRYPTO_LZ4 \
    `# Pendrives e cartões` \
    -m NLS_UTF8 -m NLS_ISO8859_1 \
    `# Os dois wifis até testar o Realtek no kernel compilado` \
    -m ATH5K -e ATH5K_PCI \
    -e STAGING -m R8188EU \
    `# Desnecessários` \
    -d X86_P4_CLOCKMOD \
    -d QRTR \
    -d ITCO_WDT \
    -d INPUT_PCSPKR \
    -d EFI_VARS_PSTORE \
    -d INPUT_JOYDEV \
    `# Build mais rápido e pacote menor` \
    -d DEBUG_INFO -d DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT -e DEBUG_INFO_NONE \
    `# Sem Secure Boot, não há por que assinar módulos (o Lockdown força a assinatura)` \
    -d SECURITY_LOCKDOWN_LSM -d MODULE_SIG

# Resolve as dependências das mudanças acima
make olddefconfig
