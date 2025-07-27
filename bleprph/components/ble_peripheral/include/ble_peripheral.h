#ifndef BLE_PERIPHERAL_H
#define BLE_PERIPHERAL_H

#include <stdbool.h>
#include "nimble/ble.h"
#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Initialize BLE peripheral
 * @return ESP_OK on success, error code otherwise
 */
esp_err_t ble_peripheral_init(void);

/**
 * @brief Start advertising
 * @return ESP_OK on success, error code otherwise
 */
esp_err_t ble_peripheral_start_advertising(void);

/**
 * @brief Stop advertising
 * @return ESP_OK on success, error code otherwise
 */
esp_err_t ble_peripheral_stop_advertising(void);

/**
 * @brief Check if connected
 * @return true if connected, false otherwise
 */
bool ble_peripheral_is_connected(void);

/**
 * @brief Get connection handle
 * @return Connection handle or BLE_HS_CONN_HANDLE_NONE if not connected
 */
uint16_t ble_peripheral_get_conn_handle(void);

#ifdef __cplusplus
}
#endif

#endif // BLE_PERIPHERAL_H 