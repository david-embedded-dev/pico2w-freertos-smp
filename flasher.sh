#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ELF_FILE="$PROJECT_DIR/build/app/pico-freertos.elf"
OPENOCD_BIN="${OPENOCD:-openocd}"

if ! command -v "$OPENOCD_BIN" >/dev/null 2>&1; then
    printf 'Error: OpenOCD not found (%s). Install it or set OPENOCD to the executable path.\n' \
        "$OPENOCD_BIN" >&2
    exit 1
fi

if [[ ! -f "$ELF_FILE" ]]; then
    printf 'Error: ELF firmware not found: %s\n' "$ELF_FILE" >&2
    printf 'Build it first with: %s/build.sh\n' "$PROJECT_DIR" >&2
    exit 1
fi

exec "$OPENOCD_BIN" \
    -f interface/cmsis-dap.cfg \
    -f target/rp2350.cfg \
    -c 'adapter speed 1000' \
    -c "program \"$ELF_FILE\" verify reset exit"
