#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ELF_FILE="$PROJECT_DIR/build/app/pico-freertos.elf"
OPENOCD_BIN="${OPENOCD:-openocd}"

if ! command -v "$OPENOCD_BIN" >/dev/null 2>&1; then
    printf 'Erro: OpenOCD não encontrado (%s). Instale-o ou defina OPENOCD com o caminho do executável.\n' \
        "$OPENOCD_BIN" >&2
    exit 1
fi

if [[ ! -f "$ELF_FILE" ]]; then
    printf 'Erro: firmware ELF não encontrado: %s\n' "$ELF_FILE" >&2
    printf 'Compile primeiro com: %s/build.sh\n' "$PROJECT_DIR" >&2
    exit 1
fi

exec "$OPENOCD_BIN" \
    -f interface/cmsis-dap.cfg \
    -f target/rp2350.cfg \
    -c 'adapter speed 1000' \
    -c "program \"$ELF_FILE\" verify reset exit"
