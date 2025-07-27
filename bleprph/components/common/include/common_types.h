#ifndef COMMON_TYPES_H
#define COMMON_TYPES_H

#include "driver/gpio.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Hardware Configuration Constants */
#define DEFAULT_LED1_GPIO       GPIO_NUM_2
#define DEFAULT_LED2_GPIO       GPIO_NUM_4
#define DEFAULT_LED3_GPIO       GPIO_NUM_5
#define DEFAULT_LED4_GPIO       GPIO_NUM_18

#define DEFAULT_MOTOR_AIN1      GPIO_NUM_26
#define DEFAULT_MOTOR_AIN2      GPIO_NUM_27
#define DEFAULT_MOTOR_BIN1      GPIO_NUM_14
#define DEFAULT_MOTOR_BIN2      GPIO_NUM_12
#define DEFAULT_MOTOR_SLEEP     GPIO_NUM_13
#define DEFAULT_MOTOR_FAULT     GPIO_NUM_25

/** System Configuration */
#define DEVICE_NAME             "ESP32_StepperMotor"
#define FIRMWARE_VERSION        "1.0.0"

/** BLE Configuration */
#define BLE_DEVICE_NAME         DEVICE_NAME
#define BLE_APPEARANCE          0x0000
#define BLE_ADV_INTERVAL_MIN    0x20    // 20ms
#define BLE_ADV_INTERVAL_MAX    0x40    // 40ms

/** Motor Configuration */
#define MOTOR_DEFAULT_SPEED     10      // ms delay between steps
#define MOTOR_MIN_SPEED         1       // minimum delay
#define MOTOR_MAX_SPEED         1000    // maximum delay

/** System Status */
typedef enum {
    SYSTEM_STATUS_INIT = 0,
    SYSTEM_STATUS_READY,
    SYSTEM_STATUS_RUNNING,
    SYSTEM_STATUS_ERROR,
    SYSTEM_STATUS_TESTING
} system_status_t;

/** Error Codes */
typedef enum {
    ERR_MOTOR_FAULT = 0x1000,
    ERR_BLE_INIT_FAILED,
    ERR_MOTOR_INIT_FAILED,
    ERR_INVALID_COMMAND,
    ERR_HARDWARE_FAULT
} system_error_t;

#ifdef __cplusplus
}
#endif

#endif // COMMON_TYPES_H 