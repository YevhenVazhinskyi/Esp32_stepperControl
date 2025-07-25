#ifndef STEPPER_MOTOR_H
#define STEPPER_MOTOR_H

#include <stdint.h>
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#ifdef __cplusplus
extern "C" {
#endif

// Motor specifications
#define STEPS_PER_ROTATION 20    // 18 degrees per step = 360/18 = 20 steps
#define STROKE_LENGTH_MM 90      // 90mm stroke length
#define STEPS_PER_MM 2.22        // Approximate steps per mm (depends on lead screw pitch)

// Motor control structure
typedef struct {
    // DRV8833 pin configuration
    gpio_num_t ain1_pin;
    gpio_num_t ain2_pin;
    gpio_num_t bin1_pin;
    gpio_num_t bin2_pin;
    gpio_num_t sleep_pin;
    gpio_num_t fault_pin;
    
    // Motor state
    int16_t current_position;    // Current position in steps
    int16_t target_position;     // Target position in steps
    uint16_t speed_delay_ms;     // Delay between steps (controls speed)
    int16_t max_position;        // Maximum position (stroke limit)
    int16_t min_position;        // Minimum position (usually 0)
    uint8_t current_step;        // Current step in sequence (0-3)
    bool is_moving;              // Movement status
    bool direction;              // 0 = backward, 1 = forward
} stepper_motor_t;

// Motor control commands
typedef enum {
    MOTOR_CMD_STOP = 0,
    MOTOR_CMD_MOVE_ABSOLUTE,
    MOTOR_CMD_MOVE_RELATIVE,
    MOTOR_CMD_HOME,
    MOTOR_CMD_SET_SPEED,
    MOTOR_CMD_ENABLE,
    MOTOR_CMD_DISABLE
} motor_command_t;

// Motor status
typedef enum {
    MOTOR_STATUS_IDLE = 0,
    MOTOR_STATUS_MOVING,
    MOTOR_STATUS_HOMING,
    MOTOR_STATUS_ERROR,
    MOTOR_STATUS_DISABLED
} motor_status_t;

// Function prototypes
esp_err_t stepper_motor_init(stepper_motor_t *motor);
esp_err_t stepper_motor_move_to_position(stepper_motor_t *motor, int16_t position);
esp_err_t stepper_motor_move_relative(stepper_motor_t *motor, int16_t steps);
esp_err_t stepper_motor_home(stepper_motor_t *motor);
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