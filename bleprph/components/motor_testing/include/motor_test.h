#ifndef MOTOR_TEST_H
#define MOTOR_TEST_H

#include "esp_err.h"
#include "stepper_motor.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Run basic motor hardware test
 * @param motor Pointer to initialized motor instance
 * @return ESP_OK on success, error code otherwise
 */
esp_err_t motor_test_hardware(stepper_motor_t *motor);

/**
 * @brief Run motor movement test (back and forth)
 * @param motor Pointer to initialized motor instance
 * @return ESP_OK on success, error code otherwise
 */
esp_err_t motor_test_movement(stepper_motor_t *motor);

/**
 * @brief Run motor position accuracy test
 * @param motor Pointer to initialized motor instance
 * @return ESP_OK on success, error code otherwise
 */
esp_err_t motor_test_position_accuracy(stepper_motor_t *motor);

/**
 * @brief Run motor speed test at different speeds
 * @param motor Pointer to initialized motor instance
 * @return ESP_OK on success, error code otherwise
 */
esp_err_t motor_test_speed_variations(stepper_motor_t *motor);

/**
 * @brief Run comprehensive motor test suite
 * @param motor Pointer to initialized motor instance
 * @return ESP_OK on success, error code otherwise
 */
esp_err_t motor_test_suite(stepper_motor_t *motor);

#ifdef __cplusplus
}
#endif

#endif // MOTOR_TEST_H 