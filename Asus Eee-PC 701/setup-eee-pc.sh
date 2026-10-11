#!/bin/bash
# Configura a máquina alvo (Eee PC 701, Debian 12 Bookworm).
# Rodar na própria máquina, como root. Pode ser rodado de novo sem problemas.
set -e
[ "$(id -u)" = 0 ] || { echo "Rode como root: sudo $0"; exit 1; }

# Troca ou acrescenta VAR=valor num arquivo de variáveis (aceita a linha comentada)
set_var() {
    local file=$1 var=$2 value=$3
    if grep -qE "^#?\s*$var=" "$file"; then
        sed -i -E "s|^#?\s*$var=.*|$var=$value|" "$file"
    else
        echo "$var=$value" >> "$file"
    fi
}

echo "== apt enxuto: listas comprimidas, sem traduções, sem deb-src"
cat > /etc/apt/apt.conf.d/99pouco-espaco <<'EOF'
Acquire::GzipIndexes "true";
Acquire::CompressionTypes::Order:: "gz";
Acquire::Languages "none";
EOF
sed -i 's/^deb-src/# deb-src/' /etc/apt/sources.list

echo "== apt sem atualizações automáticas em segundo plano"
systemctl disable --now apt-daily.timer apt-daily-upgrade.timer

echo "== pacotes: zram e firmware do wifi USB (RTL8188EUS)"
apt-get update
apt-get install -y zram-tools
[ -f /lib/firmware/rtlwifi/rtl8188eufw.bin ] || apt-get install -y firmware-realtek

echo "== zram: lz4, até metade da RAM"
antes=$(md5sum < /etc/default/zramswap)
set_var /etc/default/zramswap ALGO lz4
set_var /etc/default/zramswap PERCENT 50
# Reiniciar com o zram em uso força tudo de volta para a RAM; só se mudou algo
if [ "$antes" != "$(md5sum < /etc/default/zramswap)" ] || ! systemctl is-active -q zramswap; then
    systemctl restart zramswap
fi

echo "== journal limitado a 30 MB"
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/tamanho.conf <<'EOF'
[Journal]
SystemMaxUse=30M
EOF
systemctl restart systemd-journald

echo "== MGLRU ligado (o kernel compilado já vem assim; isto vale para o da distribuição)"
echo 'w /sys/kernel/mm/lru_gen/enabled - - - - y' > /etc/tmpfiles.d/mglru.conf
systemd-tmpfiles --create /etc/tmpfiles.d/mglru.conf || true

echo "== CPU a 900 MHz no boot (FSB 100 MHz via cpufv do eeepc_laptop)"
cat > /usr/local/sbin/eeepc-900mhz <<'EOF'
#!/bin/sh
# O eeepc_laptop bloqueia o cpufv no 701 (cpufv_disabled); libera e escolhe o modo 0
d=/sys/devices/platform/eeepc
for i in $(seq 20); do
    [ -e "$d/cpufv" ] && break
    sleep 0.5
done
[ -e "$d/cpufv_disabled" ] && echo 0 > "$d/cpufv_disabled"
echo 0 > "$d/cpufv"
EOF
chmod +x /usr/local/sbin/eeepc-900mhz
cat > /etc/systemd/system/eeepc-900mhz.service <<'EOF'
[Unit]
Description=Celeron M a 900 MHz (cpufv do eeepc_laptop)
After=systemd-modules-load.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/eeepc-900mhz

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now eeepc-900mhz.service

echo "== p4_clockmod fora do /etc/modules"
sed -i -E '/^\s*p4[-_]clockmod/d' /etc/modules
modprobe -r p4_clockmod 2>/dev/null || true

echo "== wifi interno (ath5k) em blacklist: fica só o USB"
# Não desligar o WLAN no setup: o slot some no boot e atrapalha o resto
if [ ! -f /etc/modprobe.d/ath5k-off.conf ]; then
    echo "blacklist ath5k" > /etc/modprobe.d/ath5k-off.conf
    update-initramfs -u
fi

echo "== mitigations=off no GRUB (para o kernel da distribuição; o compilado já vem sem)"
if ! grep -q 'mitigations=off' /etc/default/grub; then
    sed -i -E 's/^GRUB_CMDLINE_LINUX_DEFAULT="(.*)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 mitigations=off"/' /etc/default/grub
    update-grub
fi

echo "== reserva do ext4 na raiz: 1%"
raiz=$(findmnt -no SOURCE /)
[ "$(findmnt -no FSTYPE /)" = ext4 ] && tune2fs -m 1 "$raiz"

echo "== limpeza do apt (rode apt update antes de instalar algo)"
apt-get clean
rm -rf /var/lib/apt/lists/*

echo
echo "Pronto. Confira:"
echo "  cat /sys/devices/platform/eeepc/cpufv   # 0x200 = 900 MHz"
echo "  swapon --show                           # /dev/zram0"
echo "  cat /sys/kernel/mm/lru_gen/enabled      # diferente de 0x0000"
