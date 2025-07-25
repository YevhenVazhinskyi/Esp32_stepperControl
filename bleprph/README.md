# ESP32 BLE Peripheral with Stepper Motor Control

This example demonstrates BLE GATT Server functionality with LED control and stepper motor control via DRV8833 driver.

## Features

- **BLE GATT Server**: NimBLE-based peripheral
- **LED Control**: 4 individually controllable LEDs
- **Stepper Motor Control**: 2-phase 4-wire stepper motor with DRV8833 driver
- **Real-time Monitoring**: Position tracking and status updates
- **Flutter Integration**: Complete mobile app integration guide

## Hardware Requirements

### ESP32 Development Board
Any ESP32 board with sufficient GPIO pins

### Stepper Motor Setup
- **Motor**: 2-phase 4-wire stepper motor (18° step angle)
- **Driver**: DRV8833 dual motor driver
- **Linear Actuator**: 90mm stroke lead screw assembly

### Wiring Connections

#### DRV8833 to ESP32:
```
DRV8833 AIN1 → ESP32 GPIO21
DRV8833 AIN2 → ESP32 GPIO19
DRV8833 BIN1 → ESP32 GPIO16
DRV8833 BIN2 → ESP32 GPIO17
DRV8833 SLEEP → ESP32 GPIO23
DRV8833 FAULT → ESP32 GPIO22
```

#### LEDs to ESP32:
```
LED1 → ESP32 GPIO2
LED2 → ESP32 GPIO4
LED3 → ESP32 GPIO5
LED4 → ESP32 GPIO18
```

#### Power Connections:
```
DRV8833 VCC → 3.3V (logic)
DRV8833 VMOT → 5-12V (motor power)
DRV8833 GND → GND
```

## BLE Services

### LED Control Service
- **Service UUID**: `12345678-90ab-cdef-1234-567890abcdef`
- **Characteristics**: 4 LED control characteristics (Read/Write)

### Stepper Motor Service  
- **Service UUID**: `87654321-dcba-fedc-4321-ba0987654321`
- **Characteristics**:
  - Position Control (Read/Write/Notify)
  - Command Interface (Write)
  - Status Monitoring (Read/Notify)
  - Speed Control (Read/Write)
  - Position Limits (Read)

## Motor Specifications

- **Step Angle**: 18 degrees (20 steps per full rotation)
- **Stroke Length**: 90mm linear travel
- **Resolution**: ~2.22 steps per millimeter
- **Maximum Position**: ~200 steps
- **Speed Control**: 1-1000ms delay between steps

## Building and Flashing

### Prerequisites
- ESP-IDF v4.4 or later
- Bluetooth enabled ESP32 module

### Build Commands
```bash
idf.py set-target esp32
idf.py menuconfig  # Configure Bluetooth settings if needed
idf.py build
idf.py flash monitor
```

### Configuration Options
- Enable Bluetooth in menuconfig
- Configure log levels for debugging
- Adjust motor parameters in `stepper_motor.h`

## Mobile App Integration

Complete Flutter integration documentation is available in `FLUTTER_INTEGRATION.md`, including:

- BLE service discovery and connection
- Characteristic definitions and data formats
- Real-time position monitoring
- Motor control commands
- Status and fault monitoring
- UI components and examples

## Motor Control API

### Commands Available:
- **Move Absolute**: Move to specific position (0-200 steps)
- **Move Relative**: Move by step count (+/- steps)
- **Home**: Return to position 0
- **Stop**: Immediate stop
- **Set Speed**: Control movement speed (1-1000ms)
- **Enable/Disable**: Power control

### Safety Features:
- Position limits enforcement
- Fault detection via DRV8833 FAULT pin
- Emergency stop capability
- Power management

## Monitoring and Debugging

### Serial Output
Monitor via serial connection for debug information:
```bash
idf.py monitor
```

### BLE Scanner Apps
Use nRF Connect or similar apps to test BLE connectivity and characteristics.

### Status Indicators
- Motor status via BLE notifications
- Fault detection and reporting
- Real-time position updates

## Customization

### Motor Parameters
Edit `main/stepper_motor.h` to modify:
- Steps per rotation
- Stroke length
- Steps per millimeter
- GPIO pin assignments

### BLE Configuration
Edit `main/bleprph.h` and `main/gatt_svr.c` to modify:
- Service UUIDs
- Characteristic properties
- Data formats

## Troubleshooting

### Common Issues:
1. **Motor not moving**: Check wiring and power supply
2. **BLE connection failed**: Verify ESP32 Bluetooth configuration
3. **Position inaccurate**: Calibrate steps-per-mm for your lead screw
4. **Motor stalls**: Increase speed delay or check motor ratings
5. **Fault detected**: Check motor connections and power supply

### Debug Steps:
1. Monitor serial output for error messages
2. Test individual GPIO pins with multimeter
3. Verify BLE advertising with scanner app
4. Check motor power supply voltage and current

## License

This project is licensed under the Apache License 2.0 - see the original ESP-IDF license for details.
