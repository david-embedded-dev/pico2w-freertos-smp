add_executable(${PROJECT_NAME}
    src/main.c
)

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/include
    ${CMAKE_SOURCE_DIR}/config
)

target_link_libraries(${PROJECT_NAME}
    pico_stdlib
    pico_cyw43_arch_none
    FreeRTOS-Kernel-Static
    FreeRTOS-Kernel-Heap4
)

# Debug console through the Pico 1 Debug Probe USB-UART bridge.
pico_enable_stdio_usb(${PROJECT_NAME} 0)
pico_enable_stdio_uart(${PROJECT_NAME} 1)
target_compile_definitions(${PROJECT_NAME} PRIVATE
    PICO_DEFAULT_UART_BAUD_RATE=115200
)

# Generate UF2, BIN and other outputs
pico_add_extra_outputs(${PROJECT_NAME})
