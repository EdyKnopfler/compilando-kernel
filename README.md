# Compilando Kernel Linux

Kernels Debian customizados para máquinas específicas, compilados num contêiner Docker em outra máquina. O resultado é um `.deb` instalável com `dpkg -i`.

Cada máquina tem sua própria pasta, com tudo o que precisa: Dockerfile, scripts, config e script de configuração do sistema.

| Pasta | Máquina | Kernel |
|---|---|---|
| [Asus Eee-PC 701](Asus%20Eee-PC%20701/) | Celeron M ULV 900 MHz, 915GM, 1–2 GB | 6.1 (Debian 12 Bookworm, i386) |

## Como funciona uma pasta de máquina

```
<máquina>/
├── Dockerfile          # Debian da mesma versão/arquitetura da máquina + linux-source + flags do processador
├── .dockerignore       # kernel/ (o fonte extraído não pode entrar no contexto do build)
├── apt/sources.list    # repositórios do contêiner
├── build.sh            # constrói a imagem
├── run.sh              # abre um shell no contêiner, com kernel/ como volume e a pasta em /projeto
├── bin/                # scripts que rodam dentro do contêiner (ficam em /kernel)
│   ├── 1-extract.sh        # extrai o linux-source para o volume
│   ├── 2-machine-config.sh # copia a config da distro para o .config
│   ├── 3-tune-config.sh    # localmodconfig + ajustes da máquina
│   ├── 4-custom-config.sh  # make nconfig (opcional)
│   └── 5-build.sh          # make bindeb-pkg
├── config-<versão>     # /boot/config-$(uname -r) da máquina
├── lsmod.txt           # lsmod da máquina com tudo conectado
├── config-new          # .config resultante (para consulta e histórico)
├── setup-*.sh          # configuração do sistema na máquina alvo (idempotente)
└── kernel/             # volume com o fonte e o build (ignorado pelo git)
```

## Checklist para uma nova máquina

### 1. Coletar da máquina alvo

Instale lá o Debian que vai ficar (o kernel é compilado a partir do `linux-source` dessa mesma versão). Depois, com **todos os dispositivos em uso conectados** (pendrive, cartão SD, wifi, webcam, fone...), traga por pendrive:

```
cp /boot/config-$(uname -r) .
lsmod > lsmod.txt
cat /proc/cpuinfo > cpuinfo.txt   # modelo, flags (sse2, pae, lm...)
lspci -nn > lspci.txt
lsusb > lsusb.txt
free -m > free.txt
```

Só o que aparece no `lsmod` entra no kernel. Se algo ficou desconectado na coleta, não vai funcionar no kernel novo. Nesse caso, gere o `lsmod` de novo ou force o módulo com `-m` no `3-tune-config.sh`.

### 2. Criar a pasta

Copie a pasta de uma máquina existente (o `.dockerignore` vai junto) e apague o que é específico dela: `kernel/`, `config-*`, `lsmod.txt`, `*.deb` e `build.log`.

### 3. Ajustar

- **Nome da imagem Docker** em `build.sh` e `run.sh`. Ele precisa ser diferente para cada máquina, senão um build sobrescreve a imagem do outro (as flags do processador ficam gravadas na imagem).
- **Dockerfile:**
  - imagem base com a mesma versão e arquitetura do Debian da máquina (`i386/debian:bookworm` para 32 bits, `debian:<versão>` para 64 bits)
  - `KERNEL_VERSION` igual ao pacote `linux-source-*` dessa versão
  - `KCFLAGS`/`KCPPFLAGS` com o `-march` do processador. Para descobrir, rode na máquina alvo, se ela tiver gcc: `gcc -march=native -Q --help=target | grep -- '-march='`
- **`apt/sources.list`** com a versão certa do Debian.
- **`3-tune-config.sh`:** reescreva a lista do `scripts/config` para a nova máquina:
  - processador (`MPENTIUMM`, `MCORE2`... veja em *Processor type and features* no `make nconfig`) e se tem um ou mais núcleos (`SMP`)
  - drivers que o `localmodconfig` não pegou e que você quer garantir
  - remova o que é do Eee PC: `ATH5K`, `R8188EU`, `X86_P4_CLOCKMOD`, `MGEODE_LX`
  - as partes genéricas podem ficar: sem debug, sem assinatura de módulos, `CRYPTO_LZ4` para o zram
- **`setup-*.sh`:** só o que fizer sentido na máquina nova (o `cpufv` e o ath5k são do Eee PC; zram, journald, apt enxuto e `mitigations=off` servem para qualquer máquina fraca).
- **README da pasta:** descreva a máquina e as escolhas feitas.

### 4. Compilar

Os passos completos estão no README da pasta do Eee PC. Em resumo:

```
./build.sh
./run.sh
# dentro do contêiner:
./1-extract.sh
./2-machine-config.sh /projeto/config-<versão>
./3-tune-config.sh /projeto/lsmod.txt
./5-build.sh
cp /kernel/linux-image-*.deb /projeto/
```

Na máquina: `sudo dpkg -i linux-image-*.deb`. O kernel da distribuição continua no GRUB, em *Opções avançadas*.

### 5. Testar

Reinicie várias vezes. Um problema pode aparecer só em alguns boots. Depois de cada boot, confira:

```
sudo journalctl -b -1 -k | grep -iE 'BUG|Oops|fault|error|fail'   # boot anterior
journalctl --list-boots                                           # qual boot foi com qual kernel
```

## Regras que aprendemos

- **Uma otimização por vez.** Corte o que não é usado e mantenha os padrões da distribuição em memória, ACPI e vídeo. Se for testar algo diferente, faça num build separado e reverta se falhar. No Eee PC, `NOHIGHMEM` + `VMSPLIT_2G_OPT` causou corrupção de memória que só aparecia em alguns boots.
- **O `lsmod.txt` não pode ter permissão de execução**, como acontece com arquivos vindos de pendrive FAT. Se tiver, o `localmodconfig` executa o arquivo em vez de lê-lo e gera um kernel quase sem módulos. O `3-tune-config.sh` já trata isso fazendo uma cópia sem `+x`.
- **`tar` no volume** falha ao tentar restaurar o dono dos arquivos. Por isso o `--no-same-owner` no `1-extract.sh` e o `TAR_OPTIONS` no `5-build.sh`.
- **O `SECURITY_LOCKDOWN_LSM` força o `MODULE_SIG`.** Para desligar a assinatura de módulos, desligue os dois.
- **Depois de mudar um script em `bin/`, rode o `./build.sh` de novo.** Os scripts são copiados para dentro da imagem.
- **Mudanças que afetam o kernel inteiro**, como processador ou layout de memória, obrigam a recompilar quase tudo.

## Referências

1. https://wiki.debian.org/BuildADebianKernelPackage
2. https://www.kernel.org/doc/html/latest/admin-guide/README.html
3. https://docs.docker.com/build/concepts/context/#dockerignore-files
