# FreeRTOS SMP na Raspberry Pi Pico 2 W

**Português** | [English](README_en.md)

Projeto em C com **FreeRTOS SMP** na Raspberry Pi Pico 2 W (RP2350), explorando multitarefa, afinidade de núcleo (*Core Affinity*) e sincronização entre tarefas.

Uma Raspberry Pi Pico (RP2040) é utilizada como **PicoProbe** para gravação e depuração via SWD e comunicação UART.

<img src="images/Hardware_setup.jpeg" alt="PicoProbe e Pico 2 W conectadas para desenvolvimento" width="420">

## Implementação

A aplicação utiliza três tarefas:

| Tarefa | Núcleo | Função |
|---|---|---|
| Counter Task 0 | Core 0 | Contador de execução |
| Counter Task 1 | Core 1 | Contador de execução |
| LED Task | Core 0 | Controle do LED integrado |

O acesso à UART é protegido por Mutex. O LED é controlado pela interface CYW43.

## Requisitos

**Ambiente de desenvolvimento:**
- Ubuntu/Debian
- Git, CMake e Ninja
- GNU Arm Embedded Toolchain
- OpenOCD com suporte ao RP2350
- GDB Multiarch

Os scripts utilizam Bash. O Pico SDK e o FreeRTOS Kernel são obtidos como submódulos.

**Hardware:**
- Raspberry Pi Pico (RP2040), como PicoProbe;
- Raspberry Pi Pico 2 W (RP2350), como placa-alvo;
- Cabo USB de dados e fios para SWD, UART e GND.

A placa-alvo pode ser alimentada por USB ou pela saída VSYS da PicoProbe. Não utilize as duas fontes simultaneamente.

**Opcional:** [case impresso em 3D para a PicoProbe](https://www.thingiverse.com/thing:5566804).

## 1. Gravar o firmware da PicoProbe

Na página oficial de [releases do Debug Probe](https://github.com/raspberrypi/debugprobe/releases/latest), escolha o arquivo conforme a placa usada **como probe**:

| Placa usada como probe | Firmware |
| --- | --- |
| Raspberry Pi Pico de primeira geração (RP2040) | `debugprobe_on_pico.uf2` |
| Raspberry Pi Pico 2 (RP2350) | `debugprobe_on_pico2.uf2` |
| Raspberry Pi Debug Probe oficial | `debugprobe.uf2` |

Neste guia, a probe é uma **Pico 1**: baixe `debugprobe_on_pico.uf2`. A Pico 2 W é o alvo e receberá o firmware deste projeto na etapa de gravação; não grave nela o firmware da probe.

1. Desconecte a Pico 1.
2. Mantenha **BOOTSEL** pressionado e conecte a Pico 1 ao computador.
3. Copie `debugprobe_on_pico.uf2` para a unidade `RPI-RP2`.
4. Após reiniciar, a Pico 1 oferece CMSIS-DAP para SWD e uma interface serial USB-UART.

## 2. Conectar as placas

A placa Pico W à esquerda representa a Pico 2 W, pois ambas possuem a mesma pinagem.

<img src="images/wiring.png" alt="Diagrama de ligações entre PicoProbe e Pico 2 W" width="720">

| Finalidade | Pino da probe | Pino do alvo | Ligação |
| --- | --- | --- | --- |
| Clock SWD | GP2, pino físico 4 | SWCLK no header DEBUG | Probe GP2 → alvo SWCLK |
| Dados SWD | GP3, pino físico 5 | SWDIO no header DEBUG | Probe GP3 → alvo SWDIO |
| Terra comum | GND, pino físico 38 | GND no header DEBUG | Probe GND → alvo GND |
| UART TX da probe → RX do alvo | GP4, pino físico 6 | GP1/UART0 RX, pino físico 2 | Entrada opcional no alvo |
| UART TX do alvo → RX da probe | GP5, pino físico 7 | GP0/UART0 TX, pino físico 1 | Necessária para os logs |
| Alimentação VSYS | VSYS, pino físico 39 | VSYS, pino físico 39 | Alimentação opcional do alvo |

SWD requer SWCLK, SWDIO e GND. A direção UART TX do alvo/GP0 → RX da probe/GP5 é necessária para visualizar os contadores. UART GP4/GP1 só é necessária para enviar dados ao alvo; o exemplo não processa comandos seriais.

Conecte GND primeiro e use sinais em nível lógico de 3,3 V. VSYS é opcional. Quando estiver conectado, não ligue outra fonte USB ao alvo ao mesmo tempo.

## 3. Instalar as ferramentas de compilação

Os scripts usam Bash, CMake, Ninja e ferramentas GNU Arm Embedded. Os comandos abaixo são para Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y build-essential cmake ninja-build git \
  gcc-arm-none-eabi libnewlib-arm-none-eabi \
  libstdc++-arm-none-eabi-newlib libusb-1.0-0-dev gdb-multiarch
```

Clone o repositório e inicialize os submódulos Pico SDK e FreeRTOS Kernel:

```bash
git clone https://github.com/david-embedded-dev/pico2w-freertos-dualcore-counter.git
cd pico2w-freertos-dualcore-counter
git submodule update --init --recursive
```

## 4. Instalar OpenOCD com suporte a RP2350

O OpenOCD instalado precisa fornecer estes dois arquivos:

- `interface/cmsis-dap.cfg`
- `target/rp2350.cfg`

Pacotes antigos das distribuições podem não suportar o RP2350. O [fork OpenOCD da Raspberry Pi](https://github.com/raspberrypi/openocd) inclui suporte às placas Pico.

```bash
sudo apt install -y autoconf libtool pkg-config libusb-1.0-0-dev libhidapi-dev

git clone --recurse-submodules https://github.com/raspberrypi/openocd.git "$HOME/raspberrypi-openocd"
(
  cd "$HOME/raspberrypi-openocd"
  ./bootstrap
  ./configure --enable-cmsis-dap
  make -j"$(nproc)"
  sudo make install
)
```

Confira a instalação:

```bash
openocd --version
test -f /usr/local/share/openocd/scripts/interface/cmsis-dap.cfg && echo "CMSIS-DAP: OK"
test -f /usr/local/share/openocd/scripts/target/rp2350.cfg && echo "RP2350: OK"
```

Esses caminhos correspondem à instalação padrão em `/usr/local`. Se usar outra instalação, verifique os arquivos no diretório de scripts dela. Se houver mais de um OpenOCD instalado, confira `command -v openocd`; `flasher.sh` também aceita o caminho do executável pela variável `OPENOCD`.

## 5. Compilar

Na raiz do repositório:

```bash
./build.sh
```

O script **remove o diretório `build/` existente** e cria uma compilação limpa em modo `Debug` para `PICO_BOARD=pico2_w`, usando Ninja. Não mantenha arquivos pessoais nesse diretório. Os arquivos gerados incluem:

```text
build/app/pico-freertos.elf
build/app/pico-freertos.uf2
build/app/pico-freertos.bin
```

Equivalente manual:

```bash
cmake -S . -B build -G Ninja \
  -DPICO_BOARD=pico2_w \
  -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel "$(nproc)"
```

## 6. Gravar pela PicoProbe

Conecte o cabo USB da PicoProbe e complete as ligações SWD e GND. Em seguida:

```bash
./flasher.sh
```

O script usa o OpenOCD com `cmsis-dap.cfg` e `rp2350.cfg`, verifica o ELF na flash, reinicia o alvo e encerra.

Em caso de erro de acesso USB, configure as permissões do dispositivo, por exemplo com uma regra udev apropriada para sua distribuição.

Equivalente manual:

```bash
openocd \
  -f interface/cmsis-dap.cfg \
  -f target/rp2350.cfg \
  -c "adapter speed 1000" \
  -c "program build/app/pico-freertos.elf verify reset exit"
```

## 7. Abrir o monitor serial

1. Mantenha a PicoProbe conectada ao computador por USB.
2. No VS Code, abra uma extensão de monitor serial ou use outro programa de sua preferência.
3. Selecione a porta CDC/UART da PicoProbe; no Linux, pode ser `/dev/ttyACM0`.
4. Configure **115200 baud, 8 bits de dados, sem paridade e 1 stop bit (8N1)** e inicie o monitoramento.

A PicoProbe oferece CMSIS-DAP para gravação e uma porta CDC para a serial: selecione a porta serial. A saída USB serial da própria Pico 2 W está desabilitada neste firmware; conecte o monitor à porta da **PicoProbe**. Se perdeu as mensagens iniciais, mantenha o monitor aberto e execute `./flasher.sh` novamente em outro terminal para gravar e reiniciar o alvo.

Saída esperada:

<img src="images/Output.png" alt="Saída serial mostrando contadores nos dois núcleos" width="720">

A versão do FreeRTOS e os logs de inicialização podem variar. A ordem das mensagens não é garantida: o importante é que os contadores de `core 0` e `core 1` continuem aumentando. Cada contador começa em zero quando sua tarefa inicia, após a pausa de dois segundos na inicialização.

## Continue desenvolvendo

- Explore a criação de tarefas em `app/src/main.c`.
- Consulte `config/FreeRTOSConfig.h` para ajustar as configurações SMP e a afinidade dos núcleos.
- Após as alterações, compile com `./build.sh` e grave com `./flasher.sh`.

## Solução de problemas

- **Submódulos:** execute `git submodule update --init --recursive`.
- **OpenOCD:** confirme que a instalação possui suporte ao RP2350 e localiza `rp2350.cfg`.
- **Gravação SWD:** verifique alimentação, GND comum, SWCLK, SWDIO e permissões USB da PicoProbe.
- **Serial sem saída:** confira a porta CDC da PicoProbe, as conexões UART, o GND e a configuração 115200/8N1.
- **Mensagens iniciais ausentes:** abra o monitor serial antes de reiniciar a placa.

## Estrutura do projeto

| Caminho | Finalidade |
|---|---|
| `app/src/main.c` | Inicialização CYW43 e implementação das tarefas |
| `app/CMakeLists.txt` | Configuração do executável e das bibliotecas |
| `config/FreeRTOSConfig.h` | Configurações do FreeRTOS SMP |
| `CMakeLists.txt` | Configuração do Pico SDK e do projeto |
| `build.sh` | Compilação do firmware |
| `flasher.sh` | Gravação e verificação do firmware |

## Referências

- [Documentação Raspberry Pi Debug Probe](https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html)
- [Releases do firmware Debug Probe](https://github.com/raspberrypi/debugprobe/releases)
- [Raspberry Pi Pico SDK](https://github.com/raspberrypi/pico-sdk)
- [FreeRTOS Kernel](https://github.com/FreeRTOS/FreeRTOS-Kernel)
- [OpenOCD da Raspberry Pi](https://github.com/raspberrypi/openocd)
- [Case para PicoProbe](https://www.thingiverse.com/thing:5566804)

## Licença

Os arquivos originais deste projeto estão licenciados sob a [Licença MIT](LICENSE). Pico SDK, FreeRTOS e o case de terceiros mantêm suas respectivas licenças.