# ESP32 Stepper Motor Control Tutorial

## Introduction

This tutorial covers the stepper motor control functionality added to the ESP32 BLE Peripheral example. The system provides wireless control of a 2-phase 4-wire stepper motor via Bluetooth Low Energy (BLE), with visual feedback through LEDs.

## Hardware Overview

### Components Used
- **ESP32 Development Board** - Main controller
- **DRV8833 Dual Motor Driver** - Stepper motor driver IC
- **2-Phase 4-Wire Stepper Motor** - Linear actuator with 90mm stroke
- **4 LEDs** - Visual command feedback indicators
- **External Power Supply** - 5-12V for motor power

### Key Specifications
- **Step Angle**: 18 degrees (20 steps per full rotation)
- **Stroke Length**: 90mm linear travel
- **Resolution**: ~2.22 steps per millimeter
- **Maximum Position**: ~200 steps
- **Speed Control**: 1-1000ms delay between steps

## Pin Assignments

### GPIO Pin Mapping
| GPIO | Function | Direction | Device/Component |
|------|----------|-----------|------------------|
| GPIO2 | LED1 Control | Output | Command Feedback |
| GPIO4 | LED2 Control | Output | Status Indicator |
| GPIO5 | LED3 Control | Output | Home Command LED |
| GPIO16 | DRV8833 BIN1 | Output | Motor Phase B |
| GPIO17 | DRV8833 BIN2 | Output | Motor Phase B |
| GPIO18 | LED4 Control | Output | Stop Command LED |
| GPIO19 | DRV8833 AIN2 | Output | Motor Phase A |
| GPIO21 | DRV8833 AIN1 | Output | Motor Phase A |
| GPIO22 | DRV8833 FAULT | Input | Fault Detection |
| GPIO23 | DRV8833 SLEEP | Output | Driver Enable |

### Motor Wire Connections
| Motor Wire | Color | DRV8833 Terminal | Function |
|------------|-------|------------------|----------|
| Phase A+ | Blue | AOUT1 | Phase A Positive |
| Phase A- | Black | AOUT2 | Phase A Negative |
| Phase B+ | Red | BOUT1 | Phase B Positive |
| Phase B- | Yellow | BOUT2 | Phase B Negative |

## Software Architecture

### Core Components

#### 1. Stepper Motor Driver (`stepper_motor.h/c`)
```c
typedef struct {
    gpio_num_t ain1_pin;         // DRV8833 AIN1
    gpio_num_t ain2_pin;         // DRV8833 AIN2
    gpio_num_t bin1_pin;         // DRV8833 BIN1
    gpio_num_t bin2_pin;         // DRV8833 BIN2
    gpio_num_t sleep_pin;        // DRV8833 SLEEP
    gpio_num_t fault_pin;        // DRV8833 FAULT
    
    int16_t current_position;    // Current position in steps
    int16_t target_position;     // Target position in steps
    uint16_t speed_delay_ms;     // Delay between steps
    int16_t max_position;        // Maximum position limit
    int16_t min_position;        // Minimum position limit
    uint8_t current_step;        // Current step sequence
    bool is_moving;              // Movement status
    bool direction;              // Movement direction
} stepper_motor_t;
```

#### 2. Step Sequence Control
The driver uses a 4-step sequence for full-step operation:
```c
static const uint8_t step_sequence[4][4] = {
    {1, 0, 1, 0},  // Step 0: AIN1=1, AIN2=0, BIN1=1, BIN2=0
    {0, 1, 1, 0},  // Step 1: AIN1=0, AIN2=1, BIN1=1, BIN2=0
    {0, 1, 0, 1},  // Step 2: AIN1=0, AIN2=1, BIN1=0, BIN2=1
    {1, 0, 0, 1}   // Step 3: AIN1=1, AIN2=0, BIN1=0, BIN2=1
};
```

#### 3. FreeRTOS Task-Based Control
```c
void stepper_motor_task(void *pvParameters) {
    stepper_motor_t *motor = (stepper_motor_t *)pvParameters;
    motor_cmd_msg_t cmd;
    
    while (1) {
        // Process commands from queue
        if (xQueueReceive(motor_command_queue, &cmd, pdMS_TO_TICKS(10)) == pdTRUE) {
            // Execute command
        }
        
        // Execute movement if needed
        if (motor->is_moving && motor->current_position != motor->target_position) {
            // Step motor towards target
        }
        
        // Check for faults
        if (stepper_motor_is_fault(motor)) {
            // Handle fault condition
        }
    }
}
```

## BLE Service Implementation

### Motor Control Service
**Service UUID**: `87654321-dcba-fedc-4321-ba0987654321`

#### Characteristics Overview
1. **Position Control** (`...654301`) - Read/Write/Notify
2. **Command Interface** (`...654302`) - Write Only
3. **Status Monitoring** (`...654303`) - Read/Notify
4. **Speed Control** (`...654304`) - Read/Write
5. **Position Limits** (`...654305`) - Read Only

#### Position Control Characteristic
```c
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
```

#### Command Interface Characteristic
```c
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
        // ... other commands
    }
}
```

## LED Feedback System

### Command Indication LEDs
The system provides visual feedback for each BLE command received:

```c
static void indicate_motor_command(motor_command_t command)
{
    switch (command) {
        case MOTOR_CMD_MOVE_ABSOLUTE:
            flash_command_led(LED1_GPIO, 200);  // LED1 - 200ms flash
            break;
        case MOTOR_CMD_MOVE_RELATIVE:
            flash_command_led(LED2_GPIO, 200);  // LED2 - 200ms flash
            break;
        case MOTOR_CMD_HOME:
            flash_command_led(LED3_GPIO, 500);  // LED3 - 500ms flash
            break;
        case MOTOR_CMD_STOP:
            flash_command_led(LED4_GPIO, 100);  // LED4 - 100ms flash
            break;
        case MOTOR_CMD_SET_SPEED:
            flash_command_led(LED1_GPIO, 100);  // Double flash
            vTaskDelay(pdMS_TO_TICKS(50));
            flash_command_led(LED1_GPIO, 100);
            break;
        case MOTOR_CMD_ENABLE:
            gpio_set_level(LED2_GPIO, 1);       // LED2 solid on
            break;
        case MOTOR_CMD_DISABLE:
            gpio_set_level(LED2_GPIO, 0);       // LED2 off
            break;
    }
}
```

### LED Feedback Patterns
| Command | LED | Pattern | Duration | Meaning |
|---------|-----|---------|----------|---------|
| Move Absolute | LED1 | Single Flash | 200ms | Position command received |
| Move Relative | LED2 | Single Flash | 200ms | Relative move command |
| Home | LED3 | Single Flash | 500ms | Homing command |
| Stop | LED4 | Quick Flash | 100ms | Emergency stop |
| Set Speed | LED1 | Double Flash | 100ms + 50ms + 100ms | Speed change |
| Enable | LED2 | Solid ON | Continuous | Motor enabled |
| Disable | LED2 | OFF | Continuous | Motor disabled |

## Motor Control Commands

### Available Commands
```c
typedef enum {
    MOTOR_CMD_STOP = 0,          // Emergency stop
    MOTOR_CMD_MOVE_ABSOLUTE,     // Move to absolute position
    MOTOR_CMD_MOVE_RELATIVE,     // Move relative steps
    MOTOR_CMD_HOME,              // Return to home position
    MOTOR_CMD_SET_SPEED,         // Change movement speed
    MOTOR_CMD_ENABLE,            // Enable motor driver
    MOTOR_CMD_DISABLE            // Disable motor driver
} motor_command_t;
```

### Usage Examples

#### Absolute Movement
```c
stepper_motor_move_to_position(&g_motor_instance, 100);  // Move to step 100
```

#### Relative Movement
```c
stepper_motor_move_relative(&g_motor_instance, 50);   // Move 50 steps forward
stepper_motor_move_relative(&g_motor_instance, -25);  // Move 25 steps backward
```

#### Speed Control
```c
stepper_motor_set_speed(&g_motor_instance, 10);   // Fast (10ms between steps)
stepper_motor_set_speed(&g_motor_instance, 100);  // Slow (100ms between steps)
```

## Safety Features

### Position Limits
- **Minimum Position**: 0 steps
- **Maximum Position**: ~200 steps (90mm stroke)
- **Automatic Clamping**: Commands beyond limits are automatically constrained

### Fault Detection
```c
bool stepper_motor_is_fault(stepper_motor_t *motor) {
    return gpio_get_level(motor->fault_pin) == 0;  // DRV8833 FAULT is active low
}
```

### Emergency Stop
```c
esp_err_t stepper_motor_stop(stepper_motor_t *motor) {
    motor_cmd_msg_t cmd = {
        .command = MOTOR_CMD_STOP,
        .parameter = 0
    };
    return xQueueSend(motor_command_queue, &cmd, pdMS_TO_TICKS(100));
}
```

## Initialization Sequence

### 1. GPIO Configuration
```c
gpio_config_t io_conf = {0};
io_conf.intr_type = GPIO_INTR_DISABLE;
io_conf.mode = GPIO_MODE_OUTPUT;
io_conf.pin_bit_mask = (1ULL << motor->ain1_pin) | 
                       (1ULL << motor->ain2_pin) |
                       (1ULL << motor->bin1_pin) | 
                       (1ULL << motor->bin2_pin) |
                       (1ULL << motor->sleep_pin);
gpio_config(&io_conf);
```

### 2. Motor State Initialization
```c
motor->current_position = 0;
motor->target_position = 0;
motor->speed_delay_ms = 10;  // Default speed
motor->max_position = (int16_t)(STROKE_LENGTH_MM * STEPS_PER_MM);
motor->min_position = 0;
motor->current_step = 0;
motor->is_moving = false;
motor->direction = true;
```

### 3. Task Creation
```c
BaseType_t ret = xTaskCreate(stepper_motor_task, "motor_task", 4096, motor, 5, &motor_task_handle);
```

## Building and Testing

### Build Commands
```bash
idf.py set-target esp32
idf.py build
idf.py flash monitor
```

### Expected Serial Output
```
I (xxx) STEPPER_MOTOR: Stepper motor initialized successfully
I (xxx) NimBLE_BLE_PRPH: BLE Host Task Started
I (xxx) NimBLE_BLE_PRPH: Device Address: xx:xx:xx:xx:xx:xx
I (xxx) STEPPER_MOTOR: Motor control task started
```

### Testing with BLE Scanner
1. Use nRF Connect or similar app
2. Scan for "nimble-bleprph" device
3. Connect and discover services
4. Find Motor Service (`87654321-dcba-fedc-4321-ba0987654321`)
5. Test commands and observe LED feedback

## Mobile App Integration

### Flutter Implementation
The system includes complete Flutter integration with:
- BLE service discovery and connection
- Real-time position monitoring via notifications
- Command interface with proper data encoding
- Status monitoring with fault detection
- UI components for motor control

### Data Formats
- **Position**: int16 (little endian)
- **Commands**: [cmd:1][param:2] bytes
- **Status**: [status:1][position:2][fault:1] bytes
- **Speed**: uint16 (little endian)

## Troubleshooting

### Common Issues
1. **Motor not moving**: Check wiring and power supply
2. **Erratic movement**: Verify step sequence and timing
3. **BLE connection issues**: Check advertising and service UUIDs
4. **LED feedback not working**: Verify GPIO pin assignments
5. **Fault detection**: Monitor FAULT pin and power supply

### Debug Commands
```c
ESP_LOGI(TAG, "Motor position: %d, target: %d, moving: %d", 
         motor->current_position, motor->target_position, motor->is_moving);
ESP_LOGI(TAG, "Motor fault: %d, enabled: %d", 
         stepper_motor_is_fault(motor), gpio_get_level(motor->sleep_pin));
```

## Expansion Possibilities

### Additional Features
- **Limit Switches**: Use GPIO34, 35 for end-stop detection
- **Encoder Feedback**: Add rotary encoder for position verification
- **Second Motor**: Use GPIO13, 14, 25, 32 for additional axis
- **I2C Display**: Add real-time position display
- **Temperature Monitoring**: Monitor motor driver temperature

### Recommended Pins for Expansion
- **GPIO13, 14**: Second motor control
- **GPIO25, 26, 27**: Sensor inputs
- **GPIO32, 33**: Encoder signals
- **GPIO34, 35, 36, 39**: Limit switches (input only)

## Conclusion

This stepper motor control system provides a complete solution for wireless motor control with visual feedback. The modular design allows for easy expansion and customization while maintaining safety and reliability through proper fault detection and position limiting.

The integration of LED feedback provides immediate visual confirmation of received commands, making the system ideal for both development and production use. The BLE interface enables remote control from mobile applications while maintaining real-time status monitoring capabilities. 