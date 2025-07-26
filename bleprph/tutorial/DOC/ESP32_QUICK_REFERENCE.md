# ESP32 Stepper Motor - Quick Reference Card

## Hardware Connections (DRV8833)
```
ESP32 GPIO21 → DRV8833 AIN1   | Blue Wire (A+)   → DRV8833 AOUT1
ESP32 GPIO19 → DRV8833 AIN2   | Black Wire (A-)  → DRV8833 AOUT2  
ESP32 GPIO16 → DRV8833 BIN1   | Red Wire (B+)    → DRV8833 BOUT1
ESP32 GPIO17 → DRV8833 BIN2   | Yellow Wire (B-) → DRV8833 BOUT2
ESP32 GPIO23 → DRV8833 SLEEP  | ESP32 GND        → DRV8833 GND
ESP32 GPIO22 → DRV8833 FAULT  | ESP32 VIN        → DRV8833 VCC
```

## BLE Service
- **Service UUID**: `87654321-dcba-fedc-4321-ba0987654321`
- **Device Name**: "ESP32 Stepper Motor"

## Key Characteristics
| Function | UUID (last 2 digits) | Data Format |
|---|---|---|
| Position | `...01` | int16 (0-200 steps) |
| Command | `...02` | [cmd:1][param:2] |
| Status | `...03` | [status:1][pos:2][fault:1] |
| Speed | `...04` | uint16 (1-1000 ms) |
| Limits | `...05` | [min:2][max:2] |

## Commands
| Code | Command | Parameter | Description |
|---|---|---|---|
| 0 | STOP | 0 | Stop motor immediately |
| 1 | MOVE_ABSOLUTE | position | Move to absolute position |
| 2 | MOVE_RELATIVE | steps | Move relative steps |
| 3 | HOME | 0 | Move to position 0 |
| 4 | SET_SPEED | delay_ms | Set step delay |
| 5 | ENABLE | 0 | Enable motor |
| 6 | DISABLE | 0 | Disable motor |

## Motor Specs
- **Steps per rotation**: 20 (18° step angle)
- **Stroke length**: 90mm
- **Steps per mm**: ~2.22
- **Max position**: 200 steps
- **Speed range**: 1-1000 ms/step

## Testing Commands
```cpp
// Enable motor
Send: [5, 0, 0]

// Move 10 steps forward
Send: [2, 10, 0]

// Move to position 50
Send: [1, 50, 0]

// Set speed to 20ms/step
Send: [4, 20, 0]

// Home motor
Send: [3, 0, 0]
```

## Troubleshooting
- **No movement**: Check power, enable motor first
- **Erratic movement**: Increase step delay, check power supply
- **Connection issues**: Verify UUID, device name, BLE range
- **Position drift**: Check mechanical binding, power supply

**📋 Full Documentation**: See `ESP32_STEPPER_MOTOR_DOCUMENTATION.md`
