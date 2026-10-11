# Compilando Kernel Linux

Este projeto:

* cria um contêiner Docker rodando Debian 12 Bookworm, em 32 bits, com o código-fonte do kernel 6.1
  * a máquina alvo foi a documentada [aqui](https://github.com/EdyKnopfler/ekeke-pc) (Eee PC 701, Celeron M ULV 900 MHz)
* instala os pacotes necessários ao build
* mantém um volume com o diretório usado no build para preservar as configurações modificadas e os resultados
* monta a pasta do projeto em `/projeto`, para o contêiner enxergar os arquivos de entrada
* arquivos de entrada, trazidos da máquina alvo pelo bom e velho _pendrive-net_:
  * `config-6.1.0-37-686`: config original da distribuição (`/boot/config-$(uname -r)`)
  * `lsmod.txt`: saída do `lsmod`, gerada com todos os dispositivos em uso (pendrive, cartão SD, wifi, teclado/mouse USB...)
* `config-new`: o `.config` resultante, gerado pelo `3-tune-config.sh`:
  * só os módulos que a máquina carrega (`make localmodconfig` a partir do `lsmod.txt`)
  * processador Pentium M, núcleo único (sem SMP), sem suporte a virtualização
  * sem mitigações de Spectre/Meltdown
  * **preempção total e HZ 1000, para mais baixa latência em desktop** (ver referência)
  * MGLRU ligado e zram como módulo, para aproveitar melhor a pouca RAM
  * os dois wifis como módulo (Atheros interno e Realtek USB); o Atheros fica em blacklist na máquina
  * memória com os padrões da distribuição (`HIGHMEM4G`, `VMSPLIT_3G`): `NOHIGHMEM` + `VMSPLIT_2G_OPT` causou corrupção de memória perto da área de vídeo do 915GM
  * sem `p4_clockmod` (ele nunca subiu o clock; os 900 MHz vêm do `cpufv` do `eeepc_laptop`)
  * sem informação de debug e sem assinatura de módulos, para o build ficar mais rápido

Passos executados:

1. Executado script `./build.sh` para a construção da imagem
2. Executado script `./run.sh` (de dentro desta pasta) para execução de um shell em contêiner
3. (dentro do contêiner) `./1-extract.sh` extrai o código fonte para a pasta do volume que foi criado
4. (dentro do contêiner) `./2-machine-config.sh /projeto/config-6.1.0-37-686` copia a config da máquina para o `.config` usado no build
5. (dentro do contêiner) `./3-tune-config.sh /projeto/lsmod.txt` aplica os ajustes (ler acima)
6. (dentro do contêiner, opcional) `./4-custom-config.sh` abre o editor para ajustes manuais
7. (dentro do contêiner) as variáveis de ambiente do compilador já vêm do `Dockerfile`, otimizando para o processador (ver referência)
8. (dentro do contêiner) finalmente `./5-build.sh` executa o build específico do Debian, que gera um pacote .deb

_vai tomar um café..._

9. (ainda dentro do contêiner) copiamos o pacote para fora: `cp /kernel/linux-image-*.deb /projeto/`
10. (na máquina alvo) `sudo dpkg -i linux-image-*.deb`; o kernel da distribuição continua instalado e aparece no GRUB

A configuração da máquina alvo (clock em 900 MHz, zram, apt enxuto etc.) fica em `setup-eee-pc.sh`, para rodar lá como root.

Na máquina, o Falkon precisa de `--disable-gpu` (via `QTWEBENGINE_CHROMIUM_FLAGS`): os shaders do Chromium passam do limite da GPU do 915GM.

Referências:

1. https://wiki.debian.org/BuildADebianKernelPackage
2. https://www.linuxquestions.org/questions/debian-26/the-way-to-compile-kernel-with-mtune%3Dnative-or-march%3Dnative-788865/
3. https://codeburst.io/docker-from-scratch-2a84552470c8
4. https://devarea.com/understanding-linux-kernel-preemption/
