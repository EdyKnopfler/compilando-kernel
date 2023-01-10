# Compilando Kernel Linux

Este projeto:

* cria um contêiner Docker rodando a última versão do Debian (11 Bullseye), em 32 bits
  * a máquina alvo foi a documentada [aqui](https://github.com/EdyKnopfler/ekeke-pc)
* instala os pacotes necessários ao build
* mantém um volume com o diretório usado no build para preservar as configurações modificadas e os resultados
* arquivos de configuração de amostra:
  * `config-5.10.0-20-686-pae`: original da distribuição, copiado da máquina alvo
  * `config-new`: o `.config` resultante após as configurações:
    * configurado processador da máquina como Pentium 4 (similar)
    * removidos drivers wireless exceto o Atheros/Qualcomm da placa-mãe
    * removidos outros módulos não usados que fui capaz de reconhecer e entender (meio no chute, risco de erros, hehehe!)
    * **preempção do kernel modificada para mais baixa latência em desktop** (ver referência)
      * acho que foi o que deu mais diferença...

Passos executados:

1. Executado script `./build.sh` para a construção da imagem
2. Executado script `./run.sh` para execução de um shell em contêiner
3. (dentro do contêiner) `./1-extract.sh` extrai o código fonte para a pasta do volume que foi criado
4. copiado `/boot/config-<versão>` do kernel sendo usado na máquina alvo para a pasta do volume, usando o bom e velho _pendrive-net_
6. (dentro do contêiner) `./2-machine-config.sh config-<versão>` copiou o arquivo da máquina para o `.config` usado no build
7. (dentro do contêiner) `./3-custom-config.sh` abriu o editor para realizar as mudanças (ler acima)
8. (dentro do contêiner) setadas variáveis de ambiente do compilador para otimizar para o processador (ver referência)
9. (dentro do contêiner) finalmente `./4-build.sh` executa o build específico do Debian, que gera um pacote .deb

_vai tomar um café..._

9. (de volta ao lado de fora): pegamos o id do contêiner com `docker ps`
10. copiamos o arquivo para fora: `docker cp <id do contêiner>:/kernel/linux-image-5.10.158_5.10.158-1_i386.deb .`

Referências:

1. https://wiki.debian.org/BuildADebianKernelPackage
2. https://www.linuxquestions.org/questions/debian-26/the-way-to-compile-kernel-with-mtune%3Dnative-or-march%3Dnative-788865/
3. https://codeburst.io/docker-from-scratch-2a84552470c8
4. https://devarea.com/understanding-linux-kernel-preemption/
