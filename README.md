# FreeRTOS SMP on Raspberry Pi Pico 2 W

**English** | [Português](README.pt-BR.md)

A C project using **FreeRTOS SMP** on the Raspberry Pi Pico 2 W (RP2350), exploring multitasking, core affinity and synchronization between tasks.
<img src="images/Hardware_setup.jpeg" alt="PicoProbe connected to the Pico 2 W" width="420">

## Implementation

The application uses three tasks:

| Task | Core | Function |
|---|---|---|
| Counter Task 0 | Core 0 | Execution counter |
| Counter Task 1 | Core 1 | Execution counter |
| LED Task | Core 0 | Controls the onboard LED |

UART access is protected by a mutex. The LED is controlled through the CYW43 interface.



## Requirements

**Development environment:**
- Ubuntu/Debian
- Visual Studio Code
- Git, CMake and Ninja
- GNU Arm Embedded Toolchain
- OpenOCD with RP2350 support
- `gdb-multiarch` (or `arm-none-eabi-gdb`)
- Cortex-Debug VS Code extension

The scripts use Bash. The Pico SDK and FreeRTOS Kernel are provided as submodules.

**Hardware:**
- Raspberry Pi Pico (RP2040), used as the PicoProbe;
- Raspberry Pi Pico 2 W (RP2350), used as the target;
- USB data cable and wires for SWD, UART and GND.

The target can be powered by USB or by the PicoProbe's VSYS output. Do not use both power sources at the same time.

**Optional:** [3D-printed PicoProbe case](https://www.thingiverse.com/thing:5566804).

## 1. Flash the PicoProbe firmware

On the official [Debug Probe releases](https://github.com/raspberrypi/debugprobe/releases/latest) page, choose the firmware for the board used **as the probe**:

| Board used as the probe | Firmware |
|---|---|
| First-generation Raspberry Pi Pico (RP2040) | `debugprobe_on_pico.uf2` |
| Raspberry Pi Pico 2 (RP2350) | `debugprobe_on_pico2.uf2` |
| Official Raspberry Pi Debug Probe | `debugprobe.uf2` |

This guide uses a **Pico 1** as the probe: download `debugprobe_on_pico.uf2`. The Pico 2 W is the target and receives this project's firmware when flashing; do not install the probe firmware on it.

1. Disconnect the Pico 1.
2. Hold **BOOTSEL** while connecting the Pico 1 to the computer.
3. Copy `debugprobe_on_pico.uf2` to the `RPI-RP2` drive.
4. After reboot, the Pico 1 provides CMSIS-DAP for SWD and a USB-to-UART serial interface.

## 2. Connect the boards

The Pico W shown on the left represents the Pico 2 W because they have the same pinout.

<img src="images/wiring.png" alt="Wiring diagram for the PicoProbe and Pico 2 W" width="720">

| Purpose | Probe pin | Target pin | Connection |
|---|---|---|---|
| SWD clock | GP2, physical pin 4 | SWCLK on DEBUG header | Probe GP2 → target SWCLK |
| SWD data | GP3, physical pin 5 | SWDIO on DEBUG header | Probe GP3 → target SWDIO |
| Common ground | GND, physical pin 38 | GND on DEBUG header | Probe GND → target GND |
| Probe UART TX → target RX | GP4, physical pin 6 | GP1/UART0 RX, physical pin 2 | Optional input to target |
| Target UART TX → probe RX | GP5, physical pin 7 | GP0/UART0 TX, physical pin 1 | Required for serial logs |
| VSYS power | VSYS, physical pin 39 | VSYS, physical pin 39 | Optional target power |




## 3. Set up the environment

The scripts use Bash, CMake, Ninja and GNU Arm Embedded tools. The following commands are for Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y build-essential cmake ninja-build git \
  gcc-arm-none-eabi libnewlib-arm-none-eabi \
  libstdc++-arm-none-eabi-newlib libusb-1.0-0-dev gdb-multiarch
```

Clone the repository and initialize the Pico SDK and FreeRTOS Kernel submodules:

```bash
git clone https://github.com/david-embedded-dev/pico2w-freertos-smp.git
cd pico2w-freertos-smp
git submodule update --init --recursive
```

## 4. Install OpenOCD with RP2350 support

The OpenOCD installation must provide these files:

- `interface/cmsis-dap.cfg`
- `target/rp2350.cfg`

Older distribution packages may not support the RP2350. The Raspberry Pi [OpenOCD fork](https://github.com/raspberrypi/openocd) supports Pico-series boards.

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

Verify the installation:

```bash
openocd --version
test -f /usr/local/share/openocd/scripts/interface/cmsis-dap.cfg && echo "CMSIS-DAP: OK"
test -f /usr/local/share/openocd/scripts/target/rp2350.cfg && echo "RP2350: OK"
```

## 5. Build

From the repository root:

```bash
./build.sh
```

The script **removes the existing `build/` directory** and creates a clean Debug build for `PICO_BOARD=pico2_w` using Ninja. The generated files include:

```text
build/app/pico-freertos.elf
build/app/pico-freertos.uf2
build/app/pico-freertos.bin
```

## 6. Flash through the PicoProbe

Connect the PicoProbe USB cable and complete the SWD and GND wiring. Then run:

```bash
./flasher.sh
```

The script uses OpenOCD with `cmsis-dap.cfg` and `rp2350.cfg`, verifies the ELF in flash, resets the target and exits.

## 7. Serial monitor

To receive the logs, install and open [Serial Monitor](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-serial-monitor) or use another serial terminal. Select the probe's CDC/UART port (usually `/dev/ttyACM0` on Linux) and set **115200 baud, 8N1**.

USB serial on the Pico 2 W itself is disabled in this firmware; select the **PicoProbe** port, not the target's. If you missed the startup messages, open the monitor first and run `./flasher.sh` in another terminal to reset the board.

Expected output:

<img src="images/Output.png" alt="Serial output showing counters on both cores" width="720">

## 8. Debug

To debug, you need a PicoProbe (or another CMSIS-DAP debug probe), OpenOCD with RP2350 support, `gdb-multiarch e a extensão de depuração do VS Code:** [Cortex-Debug (`marus25.cortex-debug`)](https://marketplace.visualstudio.com/items?itemName=marus25.cortex-debug).`.

In Run and Debug, select Pico 2 W via Pico Probe and click Start Debugging. Set breakpoints and test the application. The expected output is shown below:

<p align="center">
  <img src="images/debug-vscode.png" alt="VS Code paused at a breakpoint, with debugger controls and FreeRTOS UART logs in the Serial Monitor" width="900">
</p>

*Debugging the Pico 2 W through a PicoProbe in VS Code.*

## Continue developing

- Explore task creation in `app/src/main.c`.
- Check `config/FreeRTOSConfig.h` to adjust SMP settings and core affinity.
- After changes, build with `./build.sh` and flash with `./flasher.sh`.

## Troubleshooting

- **Submodules:** run `git submodule update --init --recursive`.
- **OpenOCD:** confirm that the installation supports RP2350 and can find `rp2350.cfg`.
- **SWD flashing:** check power, common GND, SWCLK, SWDIO and PicoProbe USB permissions.
- **No serial output:** check the PicoProbe CDC port, UART connections, GND and 115200/8N1 settings.
- **Missing startup messages:** open the serial monitor before resetting the board.

## References

- [Raspberry Pi Debug Probe documentation](https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html)
- [Debug Probe firmware releases](https://github.com/raspberrypi/debugprobe/releases)
- [Raspberry Pi Pico SDK](https://github.com/raspberrypi/pico-sdk)
- [FreeRTOS Kernel](https://github.com/FreeRTOS/FreeRTOS-Kernel)
- [Raspberry Pi OpenOCD fork](https://github.com/raspberrypi/openocd)
- [PicoProbe case](https://www.thingiverse.com/thing:5566804)

## License

The original project files are licensed under the [MIT License](LICENSE). The Pico SDK, FreeRTOS and the third-party case retain their respective licenses.
