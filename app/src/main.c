#include <stdio.h>

#include "FreeRTOS.h"
#include "semphr.h"
#include "task.h"
#include "pico/cyw43_arch.h"
#include "pico/platform.h"
#include "pico/stdlib.h"
#include "pico/stdio.h"

#define COUNTER_START_DELAY_MS 2000

static SemaphoreHandle_t uart_mutex;

static void blink_task(void *params)
{
    (void) params;

    for (;;)
    {
        cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, 1);
        vTaskDelay(pdMS_TO_TICKS(50));

        cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, 0);
        vTaskDelay(pdMS_TO_TICKS(50));
    }
}

static void counter_task(void *params)
{
    (void) params;
    TickType_t last_wake = xTaskGetTickCount();
    uint32_t seconds = 0;

    for (;;)
    {
        const uint core = get_core_num();

        if (xSemaphoreTake(uart_mutex, portMAX_DELAY) == pdTRUE)
        {
            printf("core %u: %lu s\n",
                   (unsigned) core,
                   (unsigned long) seconds++);
            xSemaphoreGive(uart_mutex);
        }

        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(1000));
    }
}

static void fatal_error(const char *message)
{
    printf("ERRO: %s\n", message);
    for (;;)
    {
        tight_loop_contents();
    }
}

int main(void)
{
    stdio_init_all();

    printf("\n=== FreeRTOS SMP - Raspberry Pi Pico 2 W ===\n");
    printf("FreeRTOS Kernel: %s\n", tskKERNEL_VERSION_NUMBER);
    stdio_flush();

    if (cyw43_arch_init() != 0)
    {
        fatal_error("falha ao inicializar CYW43");
    }

    /* Force CYW43 firmware startup now so its version logs precede task logs. */
    cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, 0);
    stdio_flush();

    printf("FreeRTOS SMP configurado.\n");
    stdio_flush();
    sleep_ms(COUNTER_START_DELAY_MS);

    uart_mutex = xSemaphoreCreateMutex();
    if (uart_mutex == NULL)
    {
        fatal_error("nao foi possivel criar o mutex da UART");
    }

    if (xTaskCreateAffinitySet(blink_task, "blink", 256, NULL, 1,
                               (UBaseType_t) (1U << 0), NULL) != pdPASS)
    {
        fatal_error("nao foi possivel criar a tarefa blink");
    }

    if (xTaskCreateAffinitySet(counter_task, "counter0", 1024,
                               NULL, 1,
                               (UBaseType_t) (1U << 0), NULL) != pdPASS)
    {
        fatal_error("nao foi possivel criar a tarefa do core 0");
    }

    if (xTaskCreateAffinitySet(counter_task, "counter1", 1024,
                               NULL, 1,
                               (UBaseType_t) (1U << 1), NULL) != pdPASS)
    {
        fatal_error("nao foi possivel criar a tarefa do core 1");
    }

    vTaskStartScheduler();

    fatal_error("o scheduler FreeRTOS retornou");
    return 1;
}

void vApplicationStackOverflowHook(TaskHandle_t task, char *task_name)
{
    (void) task;
    (void) task_name;

    taskDISABLE_INTERRUPTS();
    for (;;)
    {
        tight_loop_contents();
    }
}
