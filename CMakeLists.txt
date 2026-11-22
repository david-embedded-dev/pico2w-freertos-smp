cmake_minimum_required(VERSION 3.13)

set(PROJECT_NAME pico-freertos)

# Caminho do Raspberry Pi Pico SDK (submodule)
set(PICO_SDK_PATH
    ${CMAKE_CURRENT_LIST_DIR}/libs/pico-sdk
    CACHE PATH "Path to the Raspberry Pi Pico SDK"
)

# Caminho do FreeRTOS Kernel (submodule)
set(FREERTOS_KERNEL_PATH
    ${CMAKE_CURRENT_LIST_DIR}/libs/FreeRTOS-Kernel
)

# Importa o Pico SDK
include(${PICO_SDK_PATH}/external/pico_sdk_import.cmake)

project(${PROJECT_NAME} C CXX ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Inicializa o SDK
pico_sdk_init()

# Importa o port FreeRTOS para RP2350 ARM
include(
    ${FREERTOS_KERNEL_PATH}/portable/ThirdParty/Community-Supported-Ports/GCC/RP2350_ARM_NTZ/FreeRTOS_Kernel_import.cmake
)

# Adiciona a aplicação
add_subdirectory(app)