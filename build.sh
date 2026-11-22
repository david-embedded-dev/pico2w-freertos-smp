#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

for tool in cmake ninja; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Erro: ferramenta obrigatória não encontrada: %s\n' "$tool" >&2
        exit 1
    fi
done

for dependency in \
    "$PROJECT_DIR/libs/pico-sdk/external/pico_sdk_import.cmake" \
    "$PROJECT_DIR/libs/FreeRTOS-Kernel/portable/ThirdParty/Community-Supported-Ports/GCC/RP2350_ARM_NTZ/FreeRTOS_Kernel_import.cmake"; do
    if [[ ! -f "$dependency" ]]; then
        printf 'Erro: dependência ausente: %s\n' "$dependency" >&2
        printf 'Inicialize os submódulos com: git submodule update --init --recursive\n' >&2
        exit 1
    fi
done

if command -v nproc >/dev/null 2>&1; then
    JOBS="$(nproc)"
else
    JOBS=1
fi

# Este script faz uma compilação limpa e remove somente artefatos anteriores.
rm -rf -- "$BUILD_DIR"

cmake -S "$PROJECT_DIR" -B "$BUILD_DIR" -G Ninja \
    -DPICO_BOARD=pico2_w \
    -DCMAKE_BUILD_TYPE=Debug

cmake --build "$BUILD_DIR" --parallel "$JOBS"
