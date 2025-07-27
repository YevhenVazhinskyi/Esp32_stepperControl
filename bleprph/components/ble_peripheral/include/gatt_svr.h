#ifndef GATT_SVR_H
#define GATT_SVR_H

#include "esp_err.h"
#include "host/ble_gatt.h"

#ifdef __cplusplus
extern "C" {
#endif

/** GATT server service and characteristic UUIDs */
#define GATT_SVR_SVC_ALERT_UUID               0x1811
#define GATT_SVR_CHR_SUP_NEW_ALERT_CAT_UUID   0x2A47
#define GATT_SVR_CHR_NEW_ALERT                0x2A46
#define GATT_SVR_CHR_SUP_UNR_ALERT_CAT_UUID   0x2A48
#define GATT_SVR_CHR_UNR_ALERT_STAT_UUID      0x2A45
#define GATT_SVR_CHR_ALERT_NOT_CTRL_PT        0x2A44

/** LED Control Service */
#define LED_SERVICE_UUID "12345678-90ab-cdef-1234-567890abcdef"
#define LED1_CHAR_UUID   "12345678-90ab-cdef-1234-567890abcd01"
#define LED2_CHAR_UUID   "12345678-90ab-cdef-1234-567890abcd02"
#define LED3_CHAR_UUID   "12345678-90ab-cdef-1234-567890abcd03"
#define LED4_CHAR_UUID   "12345678-90ab-cdef-1234-567890abcd04"

/** Motor Control Service */
#define MOTOR_SERVICE_UUID    "87654321-abcd-ef90-1234-567890abcdef"
#define MOTOR_POSITION_UUID   "87654321-abcd-ef90-1234-567890abcd01"
#define MOTOR_COMMAND_UUID    "87654321-abcd-ef90-1234-567890abcd02"
#define MOTOR_STATUS_UUID     "87654321-abcd-ef90-1234-567890abcd03"
#define MOTOR_SPEED_UUID      "87654321-abcd-ef90-1234-567890abcd04"

/**
 * @brief Initialize GATT server
 * @return ESP_OK on success, error code otherwise
 */
esp_err_t gatt_svr_init(void);

/**
 * @brief GATT server registration callback
 * @param ctxt Registration context
 * @param arg User argument
 */
void gatt_svr_register_cb(struct ble_gatt_register_ctxt *ctxt, void *arg);

/**
 * @brief Set motor instance for GATT server
 * @param motor Pointer to motor instance
 */
void gatt_svr_set_motor(void *motor);

#ifdef __cplusplus
}
#endif

#endif // GATT_SVR_H 