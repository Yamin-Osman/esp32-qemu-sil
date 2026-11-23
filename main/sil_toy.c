#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static int compute_output(int in)
{
    return !in;
}

static void io_task(void *arg)
{
    char line[32];
    int len = 0;                 // how many chars are in line so far

    printf("ready\n");

    while (1) {
        int c = getchar();

        if (c == EOF) {
            vTaskDelay(pdMS_TO_TICKS(10));
            continue;
        }

        if (c == '\n' || c == '\r') {
            if (len > 0) {
                line[len] = '\0';
                int value;
                int n = sscanf(line, "IN %d\n", &value);
                
                if (n==1){
                    printf("OUT %d\n", compute_output(value));
                }
                else{
                    printf("ERROR BAD INPUT\n");
                }
            }
            len = 0;
        } else if ( len < sizeof(line) - 1) {
            line[len] = c;
            len += 1;
        }
    }
}

void app_main(void)
{
    xTaskCreate(io_task, "io_task", 4096, NULL, 5, NULL);
}