# ESP32 Pin Mapping - Complete Project Overview

## Current GPIO Pin Assignments

### LED Control System
| Pin | GPIO | Function | Direction | Notes |
|-----|------|----------|-----------|-------|
| GPIO2 | LED1 | LED Control | Output | On-board LED on most ESP32 boards |
| GPIO4 | LED2 | LED Control | Output | General purpose digital pin |
| GPIO5 | LED3 | LED Control | Output | General purpose digital pin |
| GPIO18 | LED4 | LED Control | Output | SPI SCK pin (conflicts avoided) |

### Stepper Motor Control (DRV8833)
| Pin | GPIO | Function | Direction | DRV8833 Pin | Motor Wire |
|-----|------|----------|-----------|-------------|------------|
| GPIO21 | AIN1 | Motor Phase A Control | Output | AIN1 | - |
| GPIO19 | AIN2 | Motor Phase A Control | Output | AIN2 | - |
| GPIO16 | BIN1 | Motor Phase B Control | Output | BIN1 | - |
| GPIO17 | BIN2 | Motor Phase B Control | Output | BIN2 | - |
| GPIO23 | SLEEP | Motor Driver Enable | Output | SLEEP | - |
| GPIO22 | FAULT | Motor Fault Detection | Input | FAULT | - |

### Motor Wire to DRV8833 Connections
| Motor Wire Color | Motor Terminal | DRV8833 Pin | Function |
|------------------|----------------|-------------|----------|
| Blue | A+ | AOUT1 | Phase A Positive |
| Black | A- | AOUT2 | Phase A Negative |
| Red | B+ | BOUT1 | Phase B Positive |
| Yellow | B- | BOUT2 | Phase B Negative |

## Power Connections

### ESP32 Power
| Pin | Function | Voltage | Notes |
|-----|----------|---------|-------|
| 3.3V | Logic Power | 3.3V | ESP32 logic supply |
| 5V | USB Power | 5V | When powered via USB |
| GND | Ground | 0V | Common ground |

### DRV8833 Power
| Pin | Function | Voltage | Source | Notes |
|-----|----------|---------|--------|-------|
| VM | Motor Power | 5-12V | External PSU | Motor drive voltage |
| VCC | Logic Power | 3.3V | ESP32 | Logic level supply |
| GND | Ground | 0V | Common | Shared with ESP32 |

## Reserved/Special Pins (Not Used)

### Boot and Flash Pins
| Pin | Function | Notes |
|-----|----------|-------|
| GPIO0 | Boot Mode | Pull LOW for flash mode |
| GPIO1 | UART TX | Serial communication |
| GPIO3 | UART RX | Serial communication |
| GPIO6-11 | Flash SPI | Reserved for internal flash |
| GPIO12 | Boot Config | Affects boot voltage |
| GPIO15 | Boot Config | Pull LOW for normal boot |

### ADC/Touch Capable Pins (Available)
| Pin | Alt Function | Available |
|-----|--------------|-----------|
| GPIO13 | Touch4, ADC2_4 | ✅ Free |
| GPIO14 | Touch6, ADC2_6 | ✅ Free |
| GPIO25 | DAC1, ADC2_8 | ✅ Free |
| GPIO26 | DAC2, ADC2_9 | ✅ Free |
| GPIO27 | Touch7, ADC2_7 | ✅ Free |
| GPIO32 | Touch9, ADC1_4 | ✅ Free |
| GPIO33 | Touch8, ADC1_5 | ✅ Free |
| GPIO34 | ADC1_6 | ✅ Free (Input only) |
| GPIO35 | ADC1_7 | ✅ Free (Input only) |
| GPIO36 | ADC1_0 | ✅ Free (Input only) |
| GPIO39 | ADC1_3 | ✅ Free (Input only) |

## Pin Configuration Summary

### Used Pins (10 total)
- **GPIO2, 4, 5, 18** - LED Control (4 pins)
- **GPIO16, 17, 19, 21, 22, 23** - Stepper Motor (6 pins)

### Available Pins (19 total)
- **GPIO13, 14, 25, 26, 27, 32, 33** - Digital I/O with ADC
- **GPIO34, 35, 36, 39** - Input only with ADC
- **GPIO0** - Available (boot control)
- **GPIO12, 15** - Available (boot sensitive)
- **GPIO1, 3** - UART (can be repurposed)

### Reserved Pins (11 total)
- **GPIO6-11** - Flash interface (never use)
- **Power/Ground pins** - 3.3V, 5V, GND, EN

## Expansion Possibilities

### Available for Future Features
- **Sensors**: GPIO13, 14, 25-27, 32-36, 39 (ADC capable)
- **I2C**: Any two available pins (26/27 recommended)
- **SPI**: GPIO12-15 available (if not using boot functions)
- **PWM**: Any available GPIO
- **Additional Motors**: GPIO13, 14, 25, 26, 27 for second motor
- **Encoders**: GPIO32, 33 for quadrature encoder
- **Limit Switches**: GPIO34, 35, 36, 39 (input only)

### Recommended Pin Allocation for Expansion
| Feature | Recommended Pins | Notes |
|---------|------------------|-------|
| I2C Display | GPIO26 (SDA), GPIO27 (SCL) | Standard I2C pins |
| Second Motor | GPIO13, 14, 25, 32 | 4 pins for DRV8833 #2 |
| Limit Switches | GPIO34, 35 | Input only, perfect for switches |
| Rotary Encoder | GPIO36, 39 | Input only, quadrature signals |
| Temperature Sensor | GPIO33 | ADC capable for analog sensors |

## Safety Considerations

### Critical Connections
1. **Always connect GND first** - Prevents damage
2. **VM voltage** - Must match motor specifications (5-12V)
3. **Logic levels** - ESP32 is 3.3V, ensure DRV8833 compatibility
4. **Motor current** - DRV8833 max 1.2A per channel

### Pin Protection
- **Input only pins** (34-39) - No pull-up resistors available
- **Boot pins** (0, 12, 15) - Can affect startup if not handled correctly
- **Flash pins** (6-11) - Never connect external devices

## BLE Service Integration

### Service UUIDs
- **LED Service**: `12345678-90ab-cdef-1234-567890abcdef`
- **Motor Service**: `87654321-dcba-fedc-4321-ba0987654321`

### Control Methods
- **Local**: Serial commands via UART
- **Remote**: BLE GATT characteristics via mobile app
- **Hybrid**: Both methods simultaneously supported

## Troubleshooting Pin Issues

### Common Problems
1. **GPIO conflicts** - Two functions on same pin
2. **Boot issues** - Wrong state on boot pins
3. **Flash corruption** - External connections on flash pins
4. **Power issues** - Insufficient current for motors

### Debug Steps
1. Check pin assignments in code vs hardware
2. Measure voltages with multimeter
3. Test individual pins with simple blink
4. Monitor serial output for error messages
5. Use BLE scanner to verify advertising 