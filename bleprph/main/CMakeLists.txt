set(srcs "main.c"
         "gatt_svr.c")

idf_component_register(
    SRCS 
        "main.c"
    INCLUDE_DIRS 
        "."
    REQUIRES 
        nvs_flash
        log
        freertos
        stepper_motor
        ble_peripheral
        motor_testing
        common
)
