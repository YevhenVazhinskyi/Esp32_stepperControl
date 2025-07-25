set(srcs "main.c"
         "gatt_svr.c")

idf_component_register(SRCS "bleprph.h"
                            "main.c"
                            "gatt_svr.c"
                            "stepper_motor.c"
                    INCLUDE_DIRS ".")
