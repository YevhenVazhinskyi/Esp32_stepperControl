#include "stepper_motor.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"

static const char *TAG = "STEPPER_MOTOR";

// Step sequence for 2-phase stepper motor (full step)
static const uint8_t step_sequence[4][4] = {
    {1, 0, 1, 0},  // Step 0: AIN1=1, AIN2=0, BIN1=1, BIN2=0
    {0, 1, 1, 0},  // Step 1: AIN1=0, AIN2=1, BIN1=1, BIN2=0
    {0, 1, 0, 1},  // Step 2: AIN1=0, AIN2=1, BIN1=0, BIN2=1
    {1, 0, 0, 1}   // Step 3: AIN1=1, AIN2=0, BIN1=0, BIN2=1
};

// Static motor instance
static stepper_motor_t *g_motor = NULL;
static TaskHandle_t motor_task_handle = NULL;
static QueueHandle_t motor_command_queue = NULL;

// Motor command structure for queue
typedef struct {
    motor_command_t command;
    int16_t parameter;
} motor_cmd_msg_t;

// Set motor pins according to step sequence
static void set_motor_step(stepper_motor_t *motor, uint8_t step) {
    gpio_set_level(motor->ain1_pin, step_sequence[step][0]);
    gpio_set_level(motor->ain2_pin, step_sequence[step][1]);
    gpio_set_level(motor->bin1_pin, step_sequence[step][2]);
    gpio_set_level(motor->bin2_pin, step_sequence[step][3]);
}

// Stop motor (all pins low)
static void motor_stop_pins(stepper_motor_t *motor) {
    gpio_set_level(motor->ain1_pin, 0);
    gpio_set_level(motor->ain2_pin, 0);
    gpio_set_level(motor->bin1_pin, 0);
    gpio_set_level(motor->bin2_pin, 0);
}

// Initialize motor hardware and GPIO
esp_err_t stepper_motor_init(stepper_motor_t *motor) {
    if (motor == NULL) {
        return ESP_ERR_INVALID_ARG;
    }
    
    // Configure GPIO pins
    gpio_config_t io_conf = {0};
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << motor->ain1_pin) | 
                           (1ULL << motor->ain2_pin) |
                           (1ULL << motor->bin1_pin) | 
                           (1ULL << motor->bin2_pin) |
                           (1ULL << motor->sleep_pin);
    io_conf.pull_down_en = 0;
    io_conf.pull_up_en = 0;
    gpio_config(&io_conf);
    
    // Configure fault pin as input
    io_conf.mode = GPIO_MODE_INPUT;
    io_conf.pin_bit_mask = (1ULL << motor->fault_pin);
    io_conf.pull_up_en = 1;  // DRV8833 FAULT is active low
    gpio_config(&io_conf);
    
    // Initialize motor state
    motor->current_position = 0;
    motor->target_position = 0;
    motor->speed_delay_ms = 10;  // Default speed
    motor->max_position = (int16_t)(STROKE_LENGTH_MM * STEPS_PER_MM);
    motor->min_position = 0;
    motor->current_step = 0;
    motor->is_moving = false;
    motor->direction = true;
    
    // Enable motor driver
    gpio_set_level(motor->sleep_pin, 1);
    
    // Stop motor initially
    motor_stop_pins(motor);
    
    // Create command queue
    motor_command_queue = xQueueCreate(10, sizeof(motor_cmd_msg_t));
    if (motor_command_queue == NULL) {
        ESP_LOGE(TAG, "Failed to create motor command queue");
        return ESP_ERR_NO_MEM;
    }
    
    // Set global motor reference
    g_motor = motor;
    
    // Create motor control task
    BaseType_t ret = xTaskCreate(stepper_motor_task, "motor_task", 4096, motor, 5, &motor_task_handle);
    if (ret != pdPASS) {
        ESP_LOGE(TAG, "Failed to create motor task");
        return ESP_ERR_NO_MEM;
    }
    
    ESP_LOGI(TAG, "Stepper motor initialized successfully");
    return ESP_OK;
}

// Move motor to absolute position
esp_err_t stepper_motor_move_to_position(stepper_motor_t *motor, int16_t position) {
    if (motor == NULL || motor_command_queue == NULL) {
        return ESP_ERR_INVALID_STATE;
    }
    
    // Clamp position to limits
    if (position > motor->max_position) position = motor->max_position;
    if (position < motor->min_position) position = motor->min_position;
    
    motor_cmd_msg_t cmd = {
        .command = MOTOR_CMD_MOVE_ABSOLUTE,
        .parameter = position
    };
    
    if (xQueueSend(motor_command_queue, &cmd, pdMS_TO_TICKS(100)) != pdTRUE) {
        ESP_LOGE(TAG, "Failed to send move command");
        return ESP_ERR_TIMEOUT;
    }
    
    return ESP_OK;
}

// Move motor relative steps
esp_err_t stepper_motor_move_relative(stepper_motor_t *motor, int16_t steps) {
    if (motor == NULL || motor_command_queue == NULL) {
        return ESP_ERR_INVALID_STATE;
    }
    
    motor_cmd_msg_t cmd = {
        .command = MOTOR_CMD_MOVE_RELATIVE,
        .parameter = steps
    };
    
    if (xQueueSend(motor_command_queue, &cmd, pdMS_TO_TICKS(100)) != pdTRUE) {
        ESP_LOGE(TAG, "Failed to send relative move command");
        return ESP_ERR_TIMEOUT;
    }
    
    return ESP_OK;
}

// Home motor (move to position 0)
esp_err_t stepper_motor_home(stepper_motor_t *motor) {
    if (motor == NULL || motor_command_queue == NULL) {
        return ESP_ERR_INVALID_STATE;
    }
    
    motor_cmd_msg_t cmd = {
        .command = MOTOR_CMD_HOME,
        .parameter = 0
    };
    
    if (xQueueSend(motor_command_queue, &cmd, pdMS_TO_TICKS(100)) != pdTRUE) {
        ESP_LOGE(TAG, "Failed to send home command");
        return ESP_ERR_TIMEOUT;
    }
    
    return ESP_OK;
}

// Stop motor movement
esp_err_t stepper_motor_stop(stepper_motor_t *motor) {
    if (motor == NULL || motor_command_queue == NULL) {
        return ESP_ERR_INVALID_STATE;
    }
    
    motor_cmd_msg_t cmd = {
        .command = MOTOR_CMD_STOP,
        .parameter = 0
    };
    
    if (xQueueSend(motor_command_queue, &cmd, pdMS_TO_TICKS(100)) != pdTRUE) {
        ESP_LOGE(TAG, "Failed to send stop command");
        return ESP_ERR_TIMEOUT;
    }
    
    return ESP_OK;
}

// Set motor speed (delay between steps)
esp_err_t stepper_motor_set_speed(stepper_motor_t *motor, uint16_t speed_delay_ms) {
    if (motor == NULL || motor_command_queue == NULL) {
        return ESP_ERR_INVALID_STATE;
    }
    
    motor_cmd_msg_t cmd = {
        .command = MOTOR_CMD_SET_SPEED,
        .parameter = speed_delay_ms
    };
    
    if (xQueueSend(motor_command_queue, &cmd, pdMS_TO_TICKS(100)) != pdTRUE) {
        ESP_LOGE(TAG, "Failed to send speed command");
        return ESP_ERR_TIMEOUT;
    }
    
    return ESP_OK;
}

// Enable motor driver
esp_err_t stepper_motor_enable(stepper_motor_t *motor) {
    if (motor == NULL) {
        return ESP_ERR_INVALID_ARG;
    }
    
    gpio_set_level(motor->sleep_pin, 1);
    ESP_LOGI(TAG, "Motor enabled");
    return ESP_OK;
}

// Disable motor driver
esp_err_t stepper_motor_disable(stepper_motor_t *motor) {
    if (motor == NULL) {
        return ESP_ERR_INVALID_ARG;
    }
    
    gpio_set_level(motor->sleep_pin, 0);
    motor_stop_pins(motor);
    motor->is_moving = false;
    ESP_LOGI(TAG, "Motor disabled");
    return ESP_OK;
}

// Get motor status
motor_status_t stepper_motor_get_status(stepper_motor_t *motor) {
    if (motor == NULL) {
        return MOTOR_STATUS_ERROR;
    }
    
    if (gpio_get_level(motor->fault_pin) == 0) {
        return MOTOR_STATUS_ERROR;
    }
    
    if (gpio_get_level(motor->sleep_pin) == 0) {
        return MOTOR_STATUS_DISABLED;
    }
    
    if (motor->is_moving) {
        return MOTOR_STATUS_MOVING;
    }
    
    return MOTOR_STATUS_IDLE;
}

// Get current position
int16_t stepper_motor_get_position(stepper_motor_t *motor) {
    if (motor == NULL) {
        return -1;
    }
    return motor->current_position;
}

// Check fault status
bool stepper_motor_is_fault(stepper_motor_t *motor) {
    if (motor == NULL) {
        return true;
    }
    return gpio_get_level(motor->fault_pin) == 0;
}

// Motor control task
void stepper_motor_task(void *pvParameters) {
    stepper_motor_t *motor = (stepper_motor_t *)pvParameters;
    motor_cmd_msg_t cmd;
    
    ESP_LOGI(TAG, "Motor control task started");
    
    while (1) {
        // Check for commands
        if (xQueueReceive(motor_command_queue, &cmd, pdMS_TO_TICKS(10)) == pdTRUE) {
            switch (cmd.command) {
                case MOTOR_CMD_STOP:
                    motor->is_moving = false;
                    motor_stop_pins(motor);
                    ESP_LOGI(TAG, "Motor stopped");
                    break;
                    
                case MOTOR_CMD_MOVE_ABSOLUTE:
                    motor->target_position = cmd.parameter;
                    motor->is_moving = true;
                    ESP_LOGI(TAG, "Moving to position: %d", cmd.parameter);
                    break;
                    
                case MOTOR_CMD_MOVE_RELATIVE:
                    motor->target_position = motor->current_position + cmd.parameter;
                    // Clamp to limits
                    if (motor->target_position > motor->max_position) 
                        motor->target_position = motor->max_position;
                    if (motor->target_position < motor->min_position) 
                        motor->target_position = motor->min_position;
                    motor->is_moving = true;
                    ESP_LOGI(TAG, "Moving relative: %d steps, target: %d", cmd.parameter, motor->target_position);
                    break;
                    
                case MOTOR_CMD_HOME:
                    motor->target_position = 0;
                    motor->is_moving = true;
                    ESP_LOGI(TAG, "Homing motor");
                    break;
                    
                case MOTOR_CMD_SET_SPEED:
                    motor->speed_delay_ms = cmd.parameter;
                    ESP_LOGI(TAG, "Speed set to: %d ms", cmd.parameter);
                    break;
                    
                case MOTOR_CMD_ENABLE:
                    stepper_motor_enable(motor);
                    break;
                    
                case MOTOR_CMD_DISABLE:
                    stepper_motor_disable(motor);
                    break;
                    
                default:
                    ESP_LOGW(TAG, "Unknown command: %d", cmd.command);
                    break;
            }
        }
        
        // Check for faults
        if (stepper_motor_is_fault(motor)) {
            ESP_LOGE(TAG, "Motor fault detected!");
            motor->is_moving = false;
            motor_stop_pins(motor);
            vTaskDelay(pdMS_TO_TICKS(1000)); // Wait before checking again
            continue;
        }
        
        // Execute movement if needed
        if (motor->is_moving && motor->current_position != motor->target_position) {
            // Determine direction
            if (motor->current_position < motor->target_position) {
                motor->direction = true;  // Forward
                motor->current_step = (motor->current_step + 1) % 4;
                motor->current_position++;
            } else {
                motor->direction = false; // Backward
                motor->current_step = (motor->current_step + 3) % 4; // Step backward
                motor->current_position--;
            }
            
            // Set motor pins for current step
            set_motor_step(motor, motor->current_step);
            
            // Check if reached target
            if (motor->current_position == motor->target_position) {
                motor->is_moving = false;
                motor_stop_pins(motor);
                ESP_LOGI(TAG, "Reached target position: %d", motor->current_position);
            }
            
            // Delay for speed control
            vTaskDelay(pdMS_TO_TICKS(motor->speed_delay_ms));
        } else if (!motor->is_moving) {
            // If not moving, turn off motor pins to save power
            motor_stop_pins(motor);
            vTaskDelay(pdMS_TO_TICKS(100)); // Longer delay when idle
        }
    }
}

// Test function: Move motor back and forth for hardware verification
void stepper_motor_test_movement(stepper_motor_t *motor)
{
    ESP_LOGI(TAG, "Starting motor test - 10 seconds each direction");
    
    // Enable motor
    gpio_set_level(motor->sleep_pin, 1);
    vTaskDelay(pdMS_TO_TICKS(100)); // Wait for driver to wake up
    
    // Set test speed (faster for testing)
    uint16_t test_speed = 20; // 20ms between steps (relatively fast)
    
    ESP_LOGI(TAG, "Phase 1: Moving forward for 10 seconds");
    
    // Calculate start time
    TickType_t start_time = xTaskGetTickCount();
    TickType_t ten_seconds = pdMS_TO_TICKS(10000); // 10 seconds
    
    // Move forward for 10 seconds
    uint8_t step = 0;
    while ((xTaskGetTickCount() - start_time) < ten_seconds) {
        // Check for faults
        if (stepper_motor_is_fault(motor)) {
            ESP_LOGE(TAG, "Motor fault detected during test!");
            break;
        }
        
        // Set motor pins for current step (forward direction)
        set_motor_step(motor, step);
        step = (step + 1) % 4; // Move to next step
        
        vTaskDelay(pdMS_TO_TICKS(test_speed));
    }
    
    ESP_LOGI(TAG, "Phase 2: Moving backward for 10 seconds");
    
    // Reset start time for backward movement
    start_time = xTaskGetTickCount();
    
    // Move backward for 10 seconds  
    while ((xTaskGetTickCount() - start_time) < ten_seconds) {
        // Check for faults
        if (stepper_motor_is_fault(motor)) {
            ESP_LOGE(TAG, "Motor fault detected during test!");
            break;
        }
        
        // Set motor pins for current step (backward direction)
        step = (step + 3) % 4; // Move to previous step (backward)
        set_motor_step(motor, step);
        
        vTaskDelay(pdMS_TO_TICKS(test_speed));
    }
    
    // Stop motor
    motor_stop_pins(motor);
    ESP_LOGI(TAG, "Motor test completed - motor stopped");
} 