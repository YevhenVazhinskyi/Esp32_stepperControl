/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "host/ble_hs.h"
#include "host/ble_uuid.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"
#include "bleprph.h"
#include "services/ans/ble_svc_ans.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "stepper_motor.h"

/*** Forward declarations ***/
static int gatt_svr_write(struct os_mbuf *om, uint16_t min_len, uint16_t max_len,
                         void *dst, uint16_t *len);

/*** LED Control Service ***/
// GPIO pins for LEDs
#define LED1_GPIO 2
#define LED2_GPIO 4
#define LED3_GPIO 5
#define LED4_GPIO 18

// LED Service UUID
static const ble_uuid128_t led_svc_uuid =
    BLE_UUID128_INIT(0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef,
                     0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef);

// LED Characteristic UUIDs
static const ble_uuid128_t led1_chr_uuid =
    BLE_UUID128_INIT(0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef,
                     0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0x01);

static const ble_uuid128_t led2_chr_uuid =
    BLE_UUID128_INIT(0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef,
                     0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0x02);

static const ble_uuid128_t led3_chr_uuid =
    BLE_UUID128_INIT(0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef,
                     0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0x03);

static const ble_uuid128_t led4_chr_uuid =
    BLE_UUID128_INIT(0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef,
                     0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0x04);

// LED states
static uint8_t led1_state = 0;
static uint8_t led2_state = 0;
static uint8_t led3_state = 0;
static uint8_t led4_state = 0;

// LED characteristic handles
static uint16_t led1_handle;
static uint16_t led2_handle;
static uint16_t led3_handle;
static uint16_t led4_handle;

static const char *TAG = "LED_GATT";

/*** Stepper Motor Service ***/
// Motor Service UUID
static const ble_uuid128_t motor_svc_uuid =
    BLE_UUID128_INIT(0x21, 0x43, 0x65, 0x87, 0x09, 0xba, 0x21, 0x43,
                     0xdc, 0xfe, 0xba, 0xdc, 0x21, 0x43, 0x65, 0x87);

// Motor Characteristic UUIDs
static const ble_uuid128_t motor_position_chr_uuid =
    BLE_UUID128_INIT(0x01, 0x43, 0x65, 0x87, 0x09, 0xba, 0x21, 0x43,
                     0xdc, 0xfe, 0xba, 0xdc, 0x21, 0x43, 0x65, 0x87);

static const ble_uuid128_t motor_command_chr_uuid =
    BLE_UUID128_INIT(0x02, 0x43, 0x65, 0x87, 0x09, 0xba, 0x21, 0x43,
                     0xdc, 0xfe, 0xba, 0xdc, 0x21, 0x43, 0x65, 0x87);

static const ble_uuid128_t motor_status_chr_uuid =
    BLE_UUID128_INIT(0x03, 0x43, 0x65, 0x87, 0x09, 0xba, 0x21, 0x43,
                     0xdc, 0xfe, 0xba, 0xdc, 0x21, 0x43, 0x65, 0x87);

static const ble_uuid128_t motor_speed_chr_uuid =
    BLE_UUID128_INIT(0x04, 0x43, 0x65, 0x87, 0x09, 0xba, 0x21, 0x43,
                     0xdc, 0xfe, 0xba, 0xdc, 0x21, 0x43, 0x65, 0x87);

static const ble_uuid128_t motor_limits_chr_uuid =
    BLE_UUID128_INIT(0x05, 0x43, 0x65, 0x87, 0x09, 0xba, 0x21, 0x43,
                     0xdc, 0xfe, 0xba, 0xdc, 0x21, 0x43, 0x65, 0x87);

// Motor characteristic handles
static uint16_t motor_position_handle;
static uint16_t motor_command_handle;
static uint16_t motor_status_handle;
static uint16_t motor_speed_handle;
static uint16_t motor_limits_handle;

// Global motor instance
extern stepper_motor_t g_motor_instance;

// Function to initialize GPIO pins for LEDs
static void led_gpio_init(void)
{
    gpio_config_t io_conf = {0};
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << LED1_GPIO) | (1ULL << LED2_GPIO) | 
                           (1ULL << LED3_GPIO) | (1ULL << LED4_GPIO);
    io_conf.pull_down_en = 0;
    io_conf.pull_up_en = 0;
    gpio_config(&io_conf);

    // Turn off all LEDs initially
    gpio_set_level(LED1_GPIO, 0);
    gpio_set_level(LED2_GPIO, 0);
    gpio_set_level(LED3_GPIO, 0);
    gpio_set_level(LED4_GPIO, 0);
}

// Function to control LED based on GPIO pin and state
static void led_control(int gpio_pin, uint8_t state)
{
    gpio_set_level(gpio_pin, state);
    ESP_LOGI(TAG, "LED on GPIO %d set to %d", gpio_pin, state);
}

// Function to flash LED for command feedback
static void flash_command_led(int gpio_pin, int duration_ms)
{
    gpio_set_level(gpio_pin, 1);  // Turn on LED
    vTaskDelay(pdMS_TO_TICKS(duration_ms));
    gpio_set_level(gpio_pin, 0);  // Turn off LED
}

// Flash LED to indicate different motor commands
static void indicate_motor_command(motor_command_t command)
{
    switch (command) {
        case MOTOR_CMD_MOVE_ABSOLUTE:
            flash_command_led(LED1_GPIO, 200);  // LED1 - 200ms flash for absolute move
            break;
        case MOTOR_CMD_MOVE_RELATIVE:
            flash_command_led(LED2_GPIO, 200);  // LED2 - 200ms flash for relative move
            break;
        case MOTOR_CMD_HOME:
            flash_command_led(LED3_GPIO, 500);  // LED3 - 500ms flash for home command
            break;
        case MOTOR_CMD_STOP:
            flash_command_led(LED4_GPIO, 100);  // LED4 - 100ms flash for stop command
            break;
        case MOTOR_CMD_SET_SPEED:
            flash_command_led(LED1_GPIO, 100);  // LED1 - quick flash for speed change
            flash_command_led(LED1_GPIO, 100);  // Double flash
            break;
        case MOTOR_CMD_ENABLE:
            gpio_set_level(LED2_GPIO, 1);       // LED2 - solid on for enable
            break;
        case MOTOR_CMD_DISABLE:
            gpio_set_level(LED2_GPIO, 0);       // LED2 - off for disable
            break;
        default:
            break;
    }
}

// LED service access callback
static int
led_svc_access(uint16_t conn_handle, uint16_t attr_handle,
               struct ble_gatt_access_ctxt *ctxt, void *arg)
{
    int rc;
    uint8_t *led_state_ptr = NULL;
    int gpio_pin = 0;

    // Determine which LED characteristic is being accessed
    if (attr_handle == led1_handle) {
        led_state_ptr = &led1_state;
        gpio_pin = LED1_GPIO;
    } else if (attr_handle == led2_handle) {
        led_state_ptr = &led2_state;
        gpio_pin = LED2_GPIO;
    } else if (attr_handle == led3_handle) {
        led_state_ptr = &led3_state;
        gpio_pin = LED3_GPIO;
    } else if (attr_handle == led4_handle) {
        led_state_ptr = &led4_state;
        gpio_pin = LED4_GPIO;
    } else {
        return BLE_ATT_ERR_UNLIKELY;
    }

    switch (ctxt->op) {
    case BLE_GATT_ACCESS_OP_READ_CHR:
        ESP_LOGI(TAG, "LED read; conn_handle=%d attr_handle=%d", conn_handle, attr_handle);
        rc = os_mbuf_append(ctxt->om, led_state_ptr, sizeof(uint8_t));
        return rc == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;

    case BLE_GATT_ACCESS_OP_WRITE_CHR:
        ESP_LOGI(TAG, "LED write; conn_handle=%d attr_handle=%d", conn_handle, attr_handle);
        rc = gatt_svr_write(ctxt->om, sizeof(uint8_t), sizeof(uint8_t), led_state_ptr, NULL);
        if (rc == 0) {
            // Control the actual LED
            led_control(gpio_pin, *led_state_ptr);
        }
        return rc;

    default:
        return BLE_ATT_ERR_UNLIKELY;
    }
}

// Motor service access callback
static int
motor_svc_access(uint16_t conn_handle, uint16_t attr_handle,
                struct ble_gatt_access_ctxt *ctxt, void *arg)
{
    int rc;
    
    // Flash LED1 for ANY motor BLE command (read or write)
    flash_command_led(LED1_GPIO, 100);  // Quick 100ms flash
    
    if (attr_handle == motor_position_handle) {
        switch (ctxt->op) {
        case BLE_GATT_ACCESS_OP_READ_CHR:
            ESP_LOGI(TAG, "Motor position read; conn_handle=%d", conn_handle);
            int16_t position = stepper_motor_get_position(&g_motor_instance);
            rc = os_mbuf_append(ctxt->om, &position, sizeof(int16_t));
            return rc == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
            
        case BLE_GATT_ACCESS_OP_WRITE_CHR:
            ESP_LOGI(TAG, "Motor position write; conn_handle=%d", conn_handle);
            int16_t new_position;
            rc = gatt_svr_write(ctxt->om, sizeof(int16_t), sizeof(int16_t), &new_position, NULL);
            if (rc == 0) {
                // Flash LED1 to indicate position command received
                flash_command_led(LED1_GPIO, 200);
                stepper_motor_move_to_position(&g_motor_instance, new_position);
            }
            return rc;
        }
    }
    else if (attr_handle == motor_command_handle) {
        switch (ctxt->op) {
        case BLE_GATT_ACCESS_OP_WRITE_CHR:
            ESP_LOGI(TAG, "Motor command write; conn_handle=%d", conn_handle);
            
            // Command format: [command_type:1][parameter:2] = 3 bytes total
            uint8_t cmd_data[3];
            rc = gatt_svr_write(ctxt->om, 3, 3, cmd_data, NULL);
            if (rc == 0) {
                uint8_t command = cmd_data[0];
                int16_t parameter = (cmd_data[2] << 8) | cmd_data[1]; // Little endian
                
                // Flash LED to indicate command received
                indicate_motor_command((motor_command_t)command);
                
                switch (command) {
                    case MOTOR_CMD_STOP:
                        stepper_motor_stop(&g_motor_instance);
                        break;
                    case MOTOR_CMD_MOVE_ABSOLUTE:
                        stepper_motor_move_to_position(&g_motor_instance, parameter);
                        break;
                    case MOTOR_CMD_MOVE_RELATIVE:
                        stepper_motor_move_relative(&g_motor_instance, parameter);
                        break;
                    case MOTOR_CMD_HOME:
                        stepper_motor_home(&g_motor_instance);
                        break;
                    case MOTOR_CMD_SET_SPEED:
                        stepper_motor_set_speed(&g_motor_instance, (uint16_t)parameter);
                        break;
                    case MOTOR_CMD_ENABLE:
                        stepper_motor_enable(&g_motor_instance);
                        break;
                    case MOTOR_CMD_DISABLE:
                        stepper_motor_disable(&g_motor_instance);
                        break;
                    default:
                        ESP_LOGW(TAG, "Unknown motor command: %d", command);
                        return BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
                }
            }
            return rc;
        }
    }
    else if (attr_handle == motor_status_handle) {
        switch (ctxt->op) {
        case BLE_GATT_ACCESS_OP_READ_CHR:
            ESP_LOGI(TAG, "Motor status read; conn_handle=%d", conn_handle);
            
            // Status format: [status:1][position:2][is_fault:1] = 4 bytes total
            uint8_t status_data[4];
            status_data[0] = (uint8_t)stepper_motor_get_status(&g_motor_instance);
            int16_t pos = stepper_motor_get_position(&g_motor_instance);
            status_data[1] = pos & 0xFF;        // Low byte
            status_data[2] = (pos >> 8) & 0xFF; // High byte
            status_data[3] = stepper_motor_is_fault(&g_motor_instance) ? 1 : 0;
            
            rc = os_mbuf_append(ctxt->om, status_data, sizeof(status_data));
            return rc == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
        }
    }
    else if (attr_handle == motor_speed_handle) {
        switch (ctxt->op) {
        case BLE_GATT_ACCESS_OP_READ_CHR:
            ESP_LOGI(TAG, "Motor speed read; conn_handle=%d", conn_handle);
            uint16_t speed = g_motor_instance.speed_delay_ms;
            rc = os_mbuf_append(ctxt->om, &speed, sizeof(uint16_t));
            return rc == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
            
        case BLE_GATT_ACCESS_OP_WRITE_CHR:
            ESP_LOGI(TAG, "Motor speed write; conn_handle=%d", conn_handle);
            uint16_t new_speed;
            rc = gatt_svr_write(ctxt->om, sizeof(uint16_t), sizeof(uint16_t), &new_speed, NULL);
            if (rc == 0) {
                // Double flash LED1 to indicate speed change
                flash_command_led(LED1_GPIO, 100);
                vTaskDelay(pdMS_TO_TICKS(50));
                flash_command_led(LED1_GPIO, 100);
                stepper_motor_set_speed(&g_motor_instance, new_speed);
            }
            return rc;
        }
    }
    else if (attr_handle == motor_limits_handle) {
        switch (ctxt->op) {
        case BLE_GATT_ACCESS_OP_READ_CHR:
            ESP_LOGI(TAG, "Motor limits read; conn_handle=%d", conn_handle);
            
            // Limits format: [min_pos:2][max_pos:2] = 4 bytes total
            uint8_t limits_data[4];
            limits_data[0] = g_motor_instance.min_position & 0xFF;
            limits_data[1] = (g_motor_instance.min_position >> 8) & 0xFF;
            limits_data[2] = g_motor_instance.max_position & 0xFF;
            limits_data[3] = (g_motor_instance.max_position >> 8) & 0xFF;
            
            rc = os_mbuf_append(ctxt->om, limits_data, sizeof(limits_data));
            return rc == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
        }
    }
    
    return BLE_ATT_ERR_UNLIKELY;
}

/*** Maximum number of characteristics with the notify flag ***/
#define MAX_NOTIFY 5

static const ble_uuid128_t gatt_svr_svc_uuid =
    BLE_UUID128_INIT(0x2d, 0x71, 0xa2, 0x59, 0xb4, 0x58, 0xc8, 0x12,
                     0x99, 0x99, 0x43, 0x95, 0x12, 0x2f, 0x46, 0x59);

/* A characteristic that can be subscribed to */
static uint8_t gatt_svr_chr_val;
static uint16_t gatt_svr_chr_val_handle;
static const ble_uuid128_t gatt_svr_chr_uuid =
    BLE_UUID128_INIT(0x00, 0x00, 0x00, 0x00, 0x11, 0x11, 0x11, 0x11,
                     0x22, 0x22, 0x22, 0x22, 0x33, 0x33, 0x33, 0x33);

/* A custom descriptor */
static uint8_t gatt_svr_dsc_val;
static const ble_uuid128_t gatt_svr_dsc_uuid =
    BLE_UUID128_INIT(0x01, 0x01, 0x01, 0x01, 0x12, 0x12, 0x12, 0x12,
                     0x23, 0x23, 0x23, 0x23, 0x34, 0x34, 0x34, 0x34);

static int
gatt_svc_access(uint16_t conn_handle, uint16_t attr_handle,
                struct ble_gatt_access_ctxt *ctxt,
                void *arg);

static const struct ble_gatt_svc_def gatt_svr_svcs[] = {
    {
        /*** LED Control Service ***/
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = &led_svc_uuid.u,
        .characteristics = (struct ble_gatt_chr_def[])
        { {
                /*** LED 1 Characteristic ***/
                .uuid = &led1_chr_uuid.u,
                .access_cb = led_svc_access,
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_WRITE,
                .val_handle = &led1_handle,
            }, {
                /*** LED 2 Characteristic ***/
                .uuid = &led2_chr_uuid.u,
                .access_cb = led_svc_access,
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_WRITE,
                .val_handle = &led2_handle,
            }, {
                /*** LED 3 Characteristic ***/
                .uuid = &led3_chr_uuid.u,
                .access_cb = led_svc_access,
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_WRITE,
                .val_handle = &led3_handle,
            }, {
                /*** LED 4 Characteristic ***/
                .uuid = &led4_chr_uuid.u,
                .access_cb = led_svc_access,
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_WRITE,
                .val_handle = &led4_handle,
            }, {
                0, /* No more characteristics in this service. */
            }
        },
    },
    {
        /*** Stepper Motor Control Service ***/
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = &motor_svc_uuid.u,
        .characteristics = (struct ble_gatt_chr_def[])
        { {
                /*** Motor Position Characteristic ***/
                .uuid = &motor_position_chr_uuid.u,
                .access_cb = motor_svc_access,
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_WRITE | BLE_GATT_CHR_F_NOTIFY,
                .val_handle = &motor_position_handle,
            }, {
                /*** Motor Command Characteristic ***/
                .uuid = &motor_command_chr_uuid.u,
                .access_cb = motor_svc_access,
                .flags = BLE_GATT_CHR_F_WRITE,
                .val_handle = &motor_command_handle,
            }, {
                /*** Motor Status Characteristic ***/
                .uuid = &motor_status_chr_uuid.u,
                .access_cb = motor_svc_access,
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_NOTIFY,
                .val_handle = &motor_status_handle,
            }, {
                /*** Motor Speed Characteristic ***/
                .uuid = &motor_speed_chr_uuid.u,
                .access_cb = motor_svc_access,
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_WRITE,
                .val_handle = &motor_speed_handle,
            }, {
                /*** Motor Limits Characteristic ***/
                .uuid = &motor_limits_chr_uuid.u,
                .access_cb = motor_svc_access,
                .flags = BLE_GATT_CHR_F_READ,
                .val_handle = &motor_limits_handle,
            }, {
                0, /* No more characteristics in this service. */
            }
        },
    },
    {
        /*** Original Service ***/
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = &gatt_svr_svc_uuid.u,
        .characteristics = (struct ble_gatt_chr_def[])
        { {
                /*** This characteristic can be subscribed to by writing 0x00 and 0x01 to the CCCD ***/
                .uuid = &gatt_svr_chr_uuid.u,
                .access_cb = gatt_svc_access,
#if CONFIG_EXAMPLE_ENCRYPTION
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_WRITE |
                BLE_GATT_CHR_F_READ_ENC | BLE_GATT_CHR_F_WRITE_ENC |
                BLE_GATT_CHR_F_NOTIFY | BLE_GATT_CHR_F_INDICATE,
#else
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_WRITE | BLE_GATT_CHR_F_NOTIFY | BLE_GATT_CHR_F_INDICATE,
#endif
                .val_handle = &gatt_svr_chr_val_handle,
                .descriptors = (struct ble_gatt_dsc_def[])
                { {
                      .uuid = &gatt_svr_dsc_uuid.u,
#if CONFIG_EXAMPLE_ENCRYPTION
                      .att_flags = BLE_ATT_F_READ | BLE_ATT_F_READ_ENC,
#else
                      .att_flags = BLE_ATT_F_READ,
#endif
                      .access_cb = gatt_svc_access,
                    }, {
                      0, /* No more descriptors in this characteristic */
                    }
                },
            }, {
                0, /* No more characteristics in this service. */
            }
        },
    },

    {
        0, /* No more services. */
    },
};

static int
gatt_svr_write(struct os_mbuf *om, uint16_t min_len, uint16_t max_len,
               void *dst, uint16_t *len)
{
    uint16_t om_len;
    int rc;

    om_len = OS_MBUF_PKTLEN(om);
    if (om_len < min_len || om_len > max_len) {
        return BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
    }

    rc = ble_hs_mbuf_to_flat(om, dst, max_len, len);
    if (rc != 0) {
        return BLE_ATT_ERR_UNLIKELY;
    }

    return 0;
}

/**
 * Access callback whenever a characteristic/descriptor is read or written to.
 * Here reads and writes need to be handled.
 * ctxt->op tells weather the operation is read or write and
 * weather it is on a characteristic or descriptor,
 * ctxt->dsc->uuid tells which characteristic/descriptor is accessed.
 * attr_handle give the value handle of the attribute being accessed.
 * Accordingly do:
 *     Append the value to ctxt->om if the operation is READ
 *     Write ctxt->om to the value if the operation is WRITE
 **/
static int
gatt_svc_access(uint16_t conn_handle, uint16_t attr_handle,
                struct ble_gatt_access_ctxt *ctxt, void *arg)
{
    const ble_uuid_t *uuid;
    int rc;

    switch (ctxt->op) {
    case BLE_GATT_ACCESS_OP_READ_CHR:
        if (conn_handle != BLE_HS_CONN_HANDLE_NONE) {
            MODLOG_DFLT(INFO, "Characteristic read; conn_handle=%d attr_handle=%d\n",
                        conn_handle, attr_handle);
        } else {
            MODLOG_DFLT(INFO, "Characteristic read by NimBLE stack; attr_handle=%d\n",
                        attr_handle);
        }
        uuid = ctxt->chr->uuid;
        if (attr_handle == gatt_svr_chr_val_handle) {
            rc = os_mbuf_append(ctxt->om,
                                &gatt_svr_chr_val,
                                sizeof(gatt_svr_chr_val));
            return rc == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
        }
        goto unknown;

    case BLE_GATT_ACCESS_OP_WRITE_CHR:
        if (conn_handle != BLE_HS_CONN_HANDLE_NONE) {
            MODLOG_DFLT(INFO, "Characteristic write; conn_handle=%d attr_handle=%d",
                        conn_handle, attr_handle);
        } else {
            MODLOG_DFLT(INFO, "Characteristic write by NimBLE stack; attr_handle=%d",
                        attr_handle);
        }
        uuid = ctxt->chr->uuid;
        if (attr_handle == gatt_svr_chr_val_handle) {
            rc = gatt_svr_write(ctxt->om,
                                sizeof(gatt_svr_chr_val),
                                sizeof(gatt_svr_chr_val),
                                &gatt_svr_chr_val, NULL);
            ble_gatts_chr_updated(attr_handle);
            MODLOG_DFLT(INFO, "Notification/Indication scheduled for "
                        "all subscribed peers.\n");
            return rc;
        }
        goto unknown;

    case BLE_GATT_ACCESS_OP_READ_DSC:
        if (conn_handle != BLE_HS_CONN_HANDLE_NONE) {
            MODLOG_DFLT(INFO, "Descriptor read; conn_handle=%d attr_handle=%d\n",
                        conn_handle, attr_handle);
        } else {
            MODLOG_DFLT(INFO, "Descriptor read by NimBLE stack; attr_handle=%d\n",
                        attr_handle);
        }
        uuid = ctxt->dsc->uuid;
        if (ble_uuid_cmp(uuid, &gatt_svr_dsc_uuid.u) == 0) {
            rc = os_mbuf_append(ctxt->om,
                                &gatt_svr_dsc_val,
                                sizeof(gatt_svr_chr_val));
            return rc == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
        }
        goto unknown;

    case BLE_GATT_ACCESS_OP_WRITE_DSC:
        goto unknown;

    default:
        goto unknown;
    }

unknown:
    /* Unknown characteristic/descriptor;
     * The NimBLE host should not have called this function;
     */
    assert(0);
    return BLE_ATT_ERR_UNLIKELY;
}

void
gatt_svr_register_cb(struct ble_gatt_register_ctxt *ctxt, void *arg)
{
    char buf[BLE_UUID_STR_LEN];

    switch (ctxt->op) {
    case BLE_GATT_REGISTER_OP_SVC:
        MODLOG_DFLT(DEBUG, "registered service %s with handle=%d\n",
                    ble_uuid_to_str(ctxt->svc.svc_def->uuid, buf),
                    ctxt->svc.handle);
        break;

    case BLE_GATT_REGISTER_OP_CHR:
        MODLOG_DFLT(DEBUG, "registering characteristic %s with "
                    "def_handle=%d val_handle=%d\n",
                    ble_uuid_to_str(ctxt->chr.chr_def->uuid, buf),
                    ctxt->chr.def_handle,
                    ctxt->chr.val_handle);
        break;

    case BLE_GATT_REGISTER_OP_DSC:
        MODLOG_DFLT(DEBUG, "registering descriptor %s with handle=%d\n",
                    ble_uuid_to_str(ctxt->dsc.dsc_def->uuid, buf),
                    ctxt->dsc.handle);
        break;

    default:
        assert(0);
        break;
    }
}

int
gatt_svr_init(void)
{
    int rc;

    ble_svc_gap_init();
    ble_svc_gatt_init();
    ble_svc_ans_init();

    /* Initialize LED GPIOs */
    led_gpio_init();

    rc = ble_gatts_count_cfg(gatt_svr_svcs);
    if (rc != 0) {
        return rc;
    }

    rc = ble_gatts_add_svcs(gatt_svr_svcs);
    if (rc != 0) {
        return rc;
    }

    /* Setting a value for the read-only descriptor */
    gatt_svr_dsc_val = 0x99;

    return 0;
}
