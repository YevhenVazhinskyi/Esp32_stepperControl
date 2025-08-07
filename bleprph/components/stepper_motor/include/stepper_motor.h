#ifndef STEPPER_MOTOR_H
#define STEPPER_MOTOR_H

#include "esp_err.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#ifdef __cplusplus
extern "C" {
#endif

// Motor configuration constants
#define STEPS_PER_REVOLUTION    200     // 1.8° stepper motor
#define MICROSTEPS             1       // No microstepping with DRV8833
#define THREAD_PITCH_MM        2.0     // 2mm thread pitch
#define STEPS_PER_MM           (STEPS_PER_REVOLUTION * MICROSTEPS / THREAD_PITCH_MM)
#define STROKE_LENGTH_MM       30      // 30mm stroke length (calibrated for 3000 steps max)

// Motor command enumeration
typedef enum {
    MOTOR_CMD_STOP = 0,
    MOTOR_CMD_MOVE_ABSOLUTE,
    MOTOR_CMD_MOVE_RELATIVE,
    MOTOR_CMD_HOME,
    MOTOR_CMD_SET_SPEED,
    MOTOR_CMD_ENABLE,
    MOTOR_CMD_DISABLE,
    MOTOR_CMD_CALIBRATE
} motor_command_t;

// Motor status enumeration
typedef enum {
    MOTOR_STATUS_IDLE = 0,
    MOTOR_STATUS_MOVING,
    MOTOR_STATUS_ERROR,
    MOTOR_STATUS_DISABLED
} motor_status_t;

// Stepper motor structure
typedef struct {
    // GPIO pins
    gpio_num_t ain1_pin;    // AIN1 pin
    gpio_num_t ain2_pin;    // AIN2 pin
    gpio_num_t bin1_pin;    // BIN1 pin
    gpio_num_t bin2_pin;    // BIN2 pin
    gpio_num_t sleep_pin;   // SLEEP pin (enable/disable)
    gpio_num_t fault_pin;   // FAULT pin (error detection)
    
    // Motor state
    int16_t current_position;   // Current position in steps
    int16_t target_position;    // Target position in steps
    uint16_t speed_delay_ms;    // Delay between steps in milliseconds
    int16_t max_position;       // Maximum allowed position
    int16_t min_position;       // Minimum allowed position
    uint8_t current_step;       // Current step in sequence (0-3)
    bool is_moving;             // Is motor currently moving
    bool direction;             // Current direction (true = forward, false = backward)
} stepper_motor_t;

// Function declarations
esp_err_t stepper_motor_init(stepper_motor_t *motor);
esp_err_t stepper_motor_move_to_position(stepper_motor_t *motor, int16_t position);
esp_err_t stepper_motor_move_relative(stepper_motor_t *motor, int16_t steps);
esp_err_t stepper_motor_home(stepper_motor_t *motor);
esp_err_t stepper_motor_calibrate(stepper_motor_t *motor);
esp_err_t stepper_motor_stop(stepper_motor_t *motor);
esp_err_t stepper_motor_set_speed(stepper_motor_t *motor, uint16_t speed_delay_ms);
esp_err_t stepper_motor_enable(stepper_motor_t *motor);
esp_err_t stepper_motor_disable(stepper_motor_t *motor);

motor_status_t stepper_motor_get_status(stepper_motor_t *motor);
int16_t stepper_motor_get_position(stepper_motor_t *motor);
bool stepper_motor_is_fault(stepper_motor_t *motor);

void stepper_motor_task(void *pvParameters);
void stepper_motor_test_movement(stepper_motor_t *motor);

#ifdef __cplusplus
}
#endif

#endif // STEPPER_MOTOR_H