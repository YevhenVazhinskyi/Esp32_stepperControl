# ESP32 Pin Mapping - Complete Project Overview

## ⚠️ CRITICAL WARNING ⚠️
## NEVER NEVER CHANGE GPIO PINS IN CODE!
## GPIO pins are defined in: components/common/include/common_types.h
## Changing pins requires rewiring hardware which takes very long time!
## Always check common_types.h for actual pin definitions!

## Current GPIO Pin Assignments

### LED Control System
| Pin | GPIO | Function | Direction | Notes |
|-----|------|----------|-----------|-------|
| GPIO2 | LED1 | LED Control | Output | On-board LED on most ESP32 boards |
| GPIO4 | LED2 | LED Control | Output | General purpose digital pin |
| GPIO5 | LED3 | LED Control | Output | General purpose digital pin |
| GPIO18 | LED4 | LED Control | Output | SPI SCK pin (conflicts avoided) |

### Stepper Motor Control (DRV8833)
**⚠️ ACTUAL GPIO PINS ARE DEFINED IN common_types.h - NOT HERE! ⚠️**

| Function | Description |
|----------|-------------|
| AIN1 | Motor Phase A Control |
| AIN2 | Motor Phase A Control |
| BIN1 | Motor Phase B Control |
| BIN2 | Motor Phase B Control |
| SLEEP | Motor Driver Enable |
| FAULT | Motor Fault Detection |

**Check components/common/include/common_types.h for actual GPIO numbers!**

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

## ⚠️ REMEMBER: GPIO PINS ARE DEFINED IN common_types.h ⚠️
## NEVER CHANGE PINS WITHOUT REWIRING HARDWARE!