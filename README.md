# FreeRTOS SMP on Raspberry Pi Pico 2 W with PicoProbe

**English** | [Português](README.pt-BR.md)

![Physical setup with a PicoProbe connected to a Raspberry Pi Pico 2 W](images/Hardware_setup.jpeg)

*Experimental setup: the red PicoProbe programs and debugs the Pico 2 W running the FreeRTOS firmware.*

This project demonstrates an initial **FreeRTOS SMP** setup on the **Raspberry Pi Pico 2 W (RP2350)**. A first-generation **Raspberry Pi Pico (RP2040)** runs the Debug Probe firmware and acts as a PicoProbe, providing SWD programming/debugging and a USB-to-UART serial bridge.

The firmware creates two FreeRTOS tasks, pins one task to each Pico 2 W core, and reports their counters over the serial monitor. This is an experimental project for learning and embedded firmware bring-up.

> **Boards:** the Pico 1 is the debugger/probe; the Pico 2 W is the target running FreeRTOS. This repository is configured for the RP2350/Pico 2 W.

## Overview

1. Flash the Debug Probe firmware onto the Pico 1.
2. Connect SWD, UART, and optionally VSYS using the wiring table below.
3. Build the FreeRTOS firmware for the Pico 2 W.
4. Flash and debug the ELF over SWD with OpenOCD.
5. Monitor both cores through the VS Code serial monitor.

## Hardware requirements

- Raspberry Pi Pico, first generation (RP2040), used as the PicoProbe;
- Raspberry Pi Pico 2 W (RP2350), used as the target;
- USB data cable for the PicoProbe;
- jumper wires for SWD, UART, and optional VSYS power.

## 1. Set up the PicoProbe

Download `debugprobe_on_pico.uf2` from the official [Debug Probe firmware releases](https://github.com/raspberrypi/debugprobe/releases). This UF2 is for a first-generation Pico. Do not use `debugprobe.uf2`, which is intended for the official Debug Probe hardware.

1. Disconnect the Pico 1 from USB.
2. Hold **BOOTSEL** while connecting it to the computer.
3. When the `RPI-RP2` drive appears, copy `debugprobe_on_pico.uf2` to it.
4. The Pico reboots and provides CMSIS-DAP for SWD plus a USB-to-UART bridge.

## 2. Wire the debugger to the target

The diagram shows the physical setup and the six colored wires. The color codes used in the table are **VM** red, **MR** brown, **VD** green, **LJ** orange, **AZ** blue, and **AM** yellow.

![Colored wiring diagram between the PicoProbe and Pico 2 W](images/wiring.png)

| Function | Wire color | Pico debugger pin (PicoProbe) | Pico 2 W target pin | Notes |
| --- | --- | --- | --- | --- |
| SWCLK (SWD clock) | Blue | GP2 (physical pin 4) | SWCLK (DEBUG header) | SWD clock signal |
| SWDIO (SWD data) | Green | GP3 (physical pin 5) | SWDIO (DEBUG header) | Bidirectional SWD data |
| GND | Brown| GND (physical pin 38) | GND (DEBUG header) | Common electrical reference |
| UART TX → RX | Orange | GP4 (physical pin 6) | GP1 (physical pin 2, UART0 RX) | Sends data to the target |
| UART RX ← TX | Yellow | GP5 (physical pin 7) | GP0 (physical pin 1, UART0 TX) | Receives target data output |
| VSYS power | Red | VSYS (physical pin 39) | VSYS (physical pin 39) | Powers the target from the PicoProbe |

SWD requires **SWCLK, SWDIO, and GND**. To receive serial logs, also connect the Pico 2 W UART TX (GP0) to the PicoProbe UART RX (GP5). GP4/GP1 is only needed if the computer will send data to the Pico 2 W.

Connect the common GND before the signal wires. GPIO signals use 3.3 V logic. The red VSYS connection is optional; if it powers the Pico 2 W, do not connect another USB power source to the target at the same time.

### 3D-printed enclosure

The enclosure used for the PicoProbe can be 3D printed. Find the model files on [Thingiverse — PicoProbe case](https://www.thingiverse.com/thing:5566804).

## 3. Build dependencies

The following commands are for Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y build-essential cmake ninja-build git \
  gcc-arm-none-eabi libnewlib-arm-none-eabi \
  libstdc++-arm-none-eabi-newlib libusb-1.0-0-dev gdb-multiarch
```

The Pico SDK and FreeRTOS Kernel are configured as submodules under `libs/`. From the repository root, initialize them if needed:

```bash
git submodule update --init --recursive
```

### OpenOCD with RP2350 support

OpenOCD must include `interface/cmsis-dap.cfg` and `target/rp2350.cfg`. Some distributions package an older version; Raspberry Pi maintains a version in the [raspberrypi/openocd repository](https://github.com/raspberrypi/openocd).

To build and install it on Ubuntu/Debian:

```bash
sudo apt install -y autoconf libtool pkg-config libusb-1.0-0-dev libhidapi-dev
git clone --recurse-submodules https://github.com/raspberrypi/openocd.git
cd openocd
./bootstrap
./configure --enable-cmsis-dap
make -j"$(nproc)"
sudo make install
```

Check the installation and confirm that the RP2350 target script is available:

```bash
openocd --version
find /usr/share/openocd /usr/local/share/openocd -path '*/target/rp2350.cfg' 2>/dev/null
```

## 4. Build the FreeRTOS firmware

From the repository root, run:

```bash
./build.sh
```

The script configures `PICO_BOARD=pico2_w`, selects the `Debug` build type, and builds with Ninja. It removes the `build/` directory before building. The ELF used for flashing and debugging is `build/app/pico-freertos.elf`.

You can also configure and build manually:

```bash
cmake -S . -B build -G Ninja \
  -DPICO_BOARD=pico2_w \
  -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel "$(nproc)"
```

The firmware blinks the Pico 2 W LED and runs two FreeRTOS tasks with fixed core affinity: one counter on core 0 and one on core 1. UART output is configured for **115200 baud, 8N1**.

## 5. Flash with the PicoProbe

Connect the PicoProbe to the computer over USB and connect the SWD wires to the target. Then run:

```bash
./flasher.sh
```

The script uses OpenOCD to flash `build/app/pico-freertos.elf`, verify the flash contents, and reset the Pico 2 W. If you get a USB permission error, try `sudo ./flasher.sh`.

Equivalent manual command:

```bash
openocd \
  -f interface/cmsis-dap.cfg \
  -f target/rp2350.cfg \
  -c "adapter speed 1000" \
  -c "program build/app/pico-freertos.elf verify reset exit"
```

## 6. Serial monitor and output

In VS Code, open a serial monitor extension, select the PicoProbe CDC port — on Linux it is commonly `/dev/ttyACM0` — and set the baud rate to **115200**. Connect the monitor before powering the board to capture the startup banner.

The firmware prints the project name and FreeRTOS version at startup. It then initializes the CYW43, reports that the counters will start in two seconds, and prints the two core counters. The MAC address shown during runtime has been obscured in the screenshot below.

![Serial monitor output showing FreeRTOS SMP and the core counters](images/Output.png)

The `core` value is read from the core on which each task is running. Seeing both `core 0` and `core 1` demonstrates tasks running on both RP2350 cores.

## 7. Interactive debugging with GDB

After flashing the firmware, start the OpenOCD server in one terminal:

```bash
openocd -f interface/cmsis-dap.cfg \
  -f target/rp2350.cfg \
  -c "adapter speed 1000"
```

In another terminal, from the repository root, open the ELF in GDB:

```bash
gdb-multiarch build/app/pico-freertos.elf
```

At the GDB prompt, connect to OpenOCD and set a breakpoint in the counter task:

```gdb
target extended-remote localhost:3333
monitor reset init
break counter_task
continue
```

Use `continue`, `next`, and `step` to resume or step through the code. Before exiting GDB, run `monitor reset run` to leave the target running.

## Project structure

| Path | Description |
| --- | --- |
| `app/src/main.c` | Initialization, LED, and counter tasks on both cores |
| `app/CMakeLists.txt` | Application libraries and UART configuration |
| `config/FreeRTOSConfig.h` | FreeRTOS SMP and kernel configuration |
| `CMakeLists.txt` | Pico SDK and RP2350 FreeRTOS port |
| `build.sh` | Debug configuration and build |
| `flasher.sh` | Flashing and verification through OpenOCD |
| `images/` | Setup photo, wiring diagram, and serial output capture |

## References

- [Debug Probe firmware releases](https://github.com/raspberrypi/debugprobe/releases)
- [Raspberry Pi Debug Probe documentation](https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html)
- [Raspberry Pi OpenOCD](https://github.com/raspberrypi/openocd)
- [Pico SDK](https://github.com/raspberrypi/pico-sdk)
- [FreeRTOS Kernel](https://github.com/FreeRTOS/FreeRTOS-Kernel)
- [PicoProbe 3D-printed enclosure on Thingiverse](https://www.thingiverse.com/thing:5566804)
