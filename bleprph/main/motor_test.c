#include "stepper_motor.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "MOTOR_TEST";

// Test configuration
#define TEST_ENABLED 0          // Set to 0 to disable test
#define TEST_SPEED_MS 20        // Speed for test (ms between steps)
#define TEST_DURATION_SEC 10    // Duration for each direction

void run_motor_test(stepper_motor_t *motor)
{
#if TEST_ENABLED
    ESP_LOGI(TAG, "=== MOTOR HARDWARE TEST STARTING ===");
    ESP_LOGI(TAG, "Test will run %d seconds in each direction", TEST_DURATION_SEC);
    
    // Enable motor driver
    gpio_set_level(motor->sleep_pin, 1);
    vTaskDelay(pdMS_TO_TICKS(100)); // Wait for driver to stabilize
    
    // Test Phase 1: Forward movement
    ESP_LOGI(TAG, "PHASE 1: Forward movement (%d seconds)", TEST_DURATION_SEC);
    TickType_t start_time = xTaskGetTickCount();
    TickType_t test_duration = pdMS_TO_TICKS(TEST_DURATION_SEC * 1000);
    
    uint8_t step = 0;
    int step_count = 0;
    
    while ((xTaskGetTickCount() - start_time) < test_duration) {
        // Check for fault
        if (gpio_get_level(motor->fault_pin) == 0) {
            ESP_LOGE(TAG, "FAULT detected! Stopping test.");
            break;
        }
        
        // Execute step sequence (forward)
        gpio_set_level(motor->ain1_pin, (step == 0 || step == 3) ? 1 : 0);
        gpio_set_level(motor->ain2_pin, (step == 1 || step == 2) ? 1 : 0);
        gpio_set_level(motor->bin1_pin, (step == 0 || step == 1) ? 1 : 0);
        gpio_set_level(motor->bin2_pin, (step == 2 || step == 3) ? 1 : 0);
        
        step = (step + 1) % 4;
        step_count++;
        
        vTaskDelay(pdMS_TO_TICKS(TEST_SPEED_MS));
        
        // Log progress every 100 steps
        if (step_count % 100 == 0) {
            ESP_LOGI(TAG, "Forward: %d steps completed", step_count);
        }
    }
    
    ESP_LOGI(TAG, "Phase 1 completed: %d steps forward", step_count);
    
    // Brief pause between directions
    gpio_set_level(motor->ain1_pin, 0);
    gpio_set_level(motor->ain2_pin, 0);
    gpio_set_level(motor->bin1_pin, 0);
    gpio_set_level(motor->bin2_pin, 0);
    vTaskDelay(pdMS_TO_TICKS(1000)); // 1 second pause
    
    // Test Phase 2: Backward movement
    ESP_LOGI(TAG, "PHASE 2: Backward movement (%d seconds)", TEST_DURATION_SEC);
    start_time = xTaskGetTickCount();
    step_count = 0;
    
    while ((xTaskGetTickCount() - start_time) < test_duration) {
        // Check for fault
        if (gpio_get_level(motor->fault_pin) == 0) {
            ESP_LOGE(TAG, "FAULT detected! Stopping test.");
            break;
        }
        
        // Execute step sequence (backward)
        step = (step + 3) % 4; // Move backward in sequence
        
        gpio_set_level(motor->ain1_pin, (step == 0 || step == 3) ? 1 : 0);
        gpio_set_level(motor->ain2_pin, (step == 1 || step == 2) ? 1 : 0);
        gpio_set_level(motor->bin1_pin, (step == 0 || step == 1) ? 1 : 0);
        gpio_set_level(motor->bin2_pin, (step == 2 || step == 3) ? 1 : 0);
        
        step_count++;
        
        vTaskDelay(pdMS_TO_TICKS(TEST_SPEED_MS));
        
        // Log progress every 100 steps
        if (step_count % 100 == 0) {
            ESP_LOGI(TAG, "Backward: %d steps completed", step_count);
        }
    }
    
    ESP_LOGI(TAG, "Phase 2 completed: %d steps backward", step_count);
    
    // Stop motor - all pins low
    gpio_set_level(motor->ain1_pin, 0);
    gpio_set_level(motor->ain2_pin, 0);
    gpio_set_level(motor->bin1_pin, 0);
    gpio_set_level(motor->bin2_pin, 0);
    
    // Check final status
    if (gpio_get_level(motor->fault_pin) == 0) {
        ESP_LOGE(TAG, "=== TEST COMPLETED WITH FAULT ===");
    } else {
        ESP_LOGI(TAG, "=== TEST COMPLETED SUCCESSFULLY ===");
    }
    
    ESP_LOGI(TAG, "Motor is now stopped. Test configuration:");
    ESP_LOGI(TAG, "- Speed: %dms between steps", TEST_SPEED_MS);
    ESP_LOGI(TAG, "- Duration: %d seconds each direction", TEST_DURATION_SEC);
    ESP_LOGI(TAG, "- GPIO Pins: AIN1=%d, AIN2=%d, BIN1=%d, BIN2=%d", 
             motor->ain1_pin, motor->ain2_pin, motor->bin1_pin, motor->bin2_pin);
    ESP_LOGI(TAG, "- Power: SLEEP=%d, FAULT=%d", motor->sleep_pin, motor->fault_pin);
    
#else
    ESP_LOGI(TAG, "Motor test is DISABLED (TEST_ENABLED = 0)");
#endif
} 