cmake_minimum_required(VERSION 3.13)

set(PROJECT_NAME pico-freertos)

# Raspberry Pi Pico SDK submodule path
set(PICO_SDK_PATH
    ${CMAKE_CURRENT_LIST_DIR}/libs/pico-sdk
    CACHE PATH "Path to the Raspberry Pi Pico SDK"
)

# FreeRTOS Kernel submodule path
set(FREERTOS_KERNEL_PATH
    ${CMAKE_CURRENT_LIST_DIR}/libs/FreeRTOS-Kernel
)

# Importa o Pico SDK
include(${PICO_SDK_PATH}/external/pico_sdk_import.cmake)

project(${PROJECT_NAME} C CXX ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Initialize the SDK
pico_sdk_init()

# Import the FreeRTOS port for RP2350 ARM
include(
    ${FREERTOS_KERNEL_PATH}/portable/ThirdParty/Community-Supported-Ports/GCC/RP2350_ARM_NTZ/FreeRTOS_Kernel_import.cmake
)

# Add the application
add_subdirectory(app)
