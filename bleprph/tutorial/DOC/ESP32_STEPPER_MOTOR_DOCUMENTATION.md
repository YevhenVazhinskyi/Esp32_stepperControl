# ESP32 Stepper Motor Control - Complete Implementation Guide

## Table of Contents
1. [Hardware Setup](#hardware-setup)
2. [BLE Service Implementation](#ble-service-implementation)
3. [Arduino Code](#arduino-code)
4. [Pin Configuration](#pin-configuration)
5. [Testing & Troubleshooting](#testing--troubleshooting)
6. [Flutter App Integration](#flutter-app-integration)

---

## Hardware Setup

### Required Components
- **ESP32 Development Board** (ESP32-WROOM-32 or similar)
- **DRV8833 Dual Motor Driver**
- **2-Phase 4-Wire Stepper Motor** (90mm stroke, 18° step angle)
- **Power Supply** (5V-12V depending on motor specifications)
- **Jumper Wires**
- **Breadboard or PCB**

### Motor Specifications
- **Type**: 2-phase 4-wire stepper motor
- **Step Angle**: 18 degrees (20 steps per full rotation)
- **Stroke Length**: 90mm
- **Steps per mm**: ~2.22 (calculated: 200 steps ÷ 90mm)
- **Maximum Position**: ~200 steps (90mm stroke)

### Wiring Diagram

#### ESP32 to DRV8833 Connections
```
ESP32 GPIO21 → DRV8833 AIN1   (Motor Phase A Control)
ESP32 GPIO19 → DRV8833 AIN2   (Motor Phase A Control)
ESP32 GPIO16 → DRV8833 BIN1   (Motor Phase B Control)
ESP32 GPIO17 → DRV8833 BIN2   (Motor Phase B Control)
ESP32 GPIO23 → DRV8833 SLEEP  (Driver Enable/Disable)
ESP32 GPIO22 → DRV8833 FAULT  (Fault Detection Input)
ESP32 GND    → DRV8833 GND    (Common Ground)
ESP32 VIN    → DRV8833 VCC    (Power Supply)
```

#### Motor to DRV8833 Connections
```
Blue Wire (A+)   → DRV8833 AOUT1
Black Wire (A-)  → DRV8833 AOUT2  
Red Wire (B+)    → DRV8833 BOUT1
Yellow Wire (B-) → DRV8833 BOUT2
```

### Power Requirements
- **ESP32**: 3.3V (via USB or external 5V)
- **DRV8833**: 2.7V - 10.8V
- **Motor**: Check motor specifications (typically 5V-12V)

---

## BLE Service Implementation

### Service UUID Structure
```
Motor Control Service: 87654321-dcba-fedc-4321-ba0987654321
```

### Characteristics
| Characteristic | UUID | Type | Properties | Description |
|---|---|---|---|---|
| Position | `87654321-dcba-fedc-4321-ba0987654301` | int16 | Read/Write/Notify | Current position (0-200 steps) |
| Command | `87654321-dcba-fedc-4321-ba0987654302` | 3 bytes | Write | Motor control commands |
| Status | `87654321-dcba-fedc-4321-ba0987654303` | 4 bytes | Read/Notify | Motor status and fault info |
| Speed | `87654321-dcba-fedc-4321-ba0987654304` | uint16 | Read/Write | Step delay (1-1000 ms) |
| Limits | `87654321-dcba-fedc-4321-ba0987654305` | 4 bytes | Read | Position limits (min/max) |

### Data Formats

#### Command Characteristic (3 bytes)
```
Byte 0: Command Type
Byte 1-2: Parameter (int16, little endian)

Commands:
0 = STOP
1 = MOVE_ABSOLUTE (parameter = target position)
2 = MOVE_RELATIVE (parameter = steps to move)
3 = HOME (parameter = 0)
4 = SET_SPEED (parameter = delay in ms)
5 = ENABLE (parameter = 0)
6 = DISABLE (parameter = 0)
```

#### Status Characteristic (4 bytes)
```
Byte 0: Motor Status
  0 = IDLE
  1 = MOVING
  2 = HOMING
  3 = ERROR
  4 = DISABLED

Byte 1-2: Current Position (int16, little endian)
Byte 3: Fault Status (0 = OK, 1 = FAULT)
```

#### Position Characteristic (2 bytes)
```
Bytes 0-1: Position (int16, little endian, 0-200 steps)
```

#### Speed Characteristic (2 bytes)
```
Bytes 0-1: Step Delay (uint16, little endian, 1-1000 ms)
```

#### Limits Characteristic (4 bytes)
```
Bytes 0-1: Minimum Position (int16, little endian)
Bytes 2-3: Maximum Position (int16, little endian)
```

---

## Arduino Code

### Required Libraries
```cpp
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
```

### Pin Definitions
```cpp
// Motor Control Pins
#define MOTOR_AIN1_PIN 21
#define MOTOR_AIN2_PIN 19
#define MOTOR_BIN1_PIN 16
#define MOTOR_BIN2_PIN 17
#define MOTOR_SLEEP_PIN 23
#define MOTOR_FAULT_PIN 22

// Motor Configuration
#define STEPS_PER_REVOLUTION 20
#define MAX_POSITION 200
#define MIN_POSITION 0
#define DEFAULT_SPEED_MS 10
```

### BLE Service Setup
```cpp
// Service and Characteristic UUIDs
#define SERVICE_UUID "87654321-dcba-fedc-4321-ba0987654321"
#define POSITION_CHAR_UUID "87654321-dcba-fedc-4321-ba0987654301"
#define COMMAND_CHAR_UUID "87654321-dcba-fedc-4321-ba0987654302"
#define STATUS_CHAR_UUID "87654321-dcba-fedc-4321-ba0987654303"
#define SPEED_CHAR_UUID "87654321-dcba-fedc-4321-ba0987654304"
#define LIMITS_CHAR_UUID "87654321-dcba-fedc-4321-ba0987654305"

BLEServer* pServer = nullptr;
BLEService* pService = nullptr;
BLECharacteristic* pPositionChar = nullptr;
BLECharacteristic* pCommandChar = nullptr;
BLECharacteristic* pStatusChar = nullptr;
BLECharacteristic* pSpeedChar = nullptr;
BLECharacteristic* pLimitsChar = nullptr;
```

### Motor Control Class
```cpp
class StepperMotor {
private:
  int currentPosition = 0;
  int targetPosition = 0;
  int stepDelay = DEFAULT_SPEED_MS;
  bool isEnabled = false;
  bool isMoving = false;
  bool hasFault = false;
  
  // Step sequence for 4-wire stepper motor
  int stepSequence[4][4] = {
    {1, 0, 1, 0},
    {0, 1, 1, 0},
    {0, 1, 0, 1},
    {1, 0, 0, 1}
  };
  
public:
  void setup() {
    pinMode(MOTOR_AIN1_PIN, OUTPUT);
    pinMode(MOTOR_AIN2_PIN, OUTPUT);
    pinMode(MOTOR_BIN1_PIN, OUTPUT);
    pinMode(MOTOR_BIN2_PIN, OUTPUT);
    pinMode(MOTOR_SLEEP_PIN, OUTPUT);
    pinMode(MOTOR_FAULT_PIN, INPUT_PULLUP);
    
    disable(); // Start disabled for safety
  }
  
  void enable() {
    digitalWrite(MOTOR_SLEEP_PIN, HIGH);
    isEnabled = true;
    delay(1); // Allow driver to wake up
  }
  
  void disable() {
    digitalWrite(MOTOR_SLEEP_PIN, LOW);
    digitalWrite(MOTOR_AIN1_PIN, LOW);
    digitalWrite(MOTOR_AIN2_PIN, LOW);
    digitalWrite(MOTOR_BIN1_PIN, LOW);
    digitalWrite(MOTOR_BIN2_PIN, LOW);
    isEnabled = false;
    isMoving = false;
  }
  
  void moveToPosition(int position) {
    if (!isEnabled) return;
    if (position < MIN_POSITION) position = MIN_POSITION;
    if (position > MAX_POSITION) position = MAX_POSITION;
    
    targetPosition = position;
    isMoving = true;
  }
  
  void moveRelative(int steps) {
    moveToPosition(currentPosition + steps);
  }
  
  void home() {
    moveToPosition(MIN_POSITION);
  }
  
  void stop() {
    targetPosition = currentPosition;
    isMoving = false;
  }
  
  void setSpeed(int delayMs) {
    if (delayMs < 1) delayMs = 1;
    if (delayMs > 1000) delayMs = 1000;
    stepDelay = delayMs;
  }
  
  void update() {
    if (!isEnabled || !isMoving) return;
    
    // Check for fault
    if (digitalRead(MOTOR_FAULT_PIN) == LOW) {
      hasFault = true;
      stop();
      disable();
      return;
    }
    
    if (currentPosition != targetPosition) {
      int direction = (targetPosition > currentPosition) ? 1 : -1;
      step(direction);
      currentPosition += direction;
      
      if (currentPosition == targetPosition) {
        isMoving = false;
      }
      
      delay(stepDelay);
    }
  }
  
  void step(int direction) {
    static int stepIndex = 0;
    
    if (direction > 0) {
      stepIndex = (stepIndex + 1) % 4;
    } else {
      stepIndex = (stepIndex - 1 + 4) % 4;
    }
    
    digitalWrite(MOTOR_AIN1_PIN, stepSequence[stepIndex][0]);
    digitalWrite(MOTOR_AIN2_PIN, stepSequence[stepIndex][1]);
    digitalWrite(MOTOR_BIN1_PIN, stepSequence[stepIndex][2]);
    digitalWrite(MOTOR_BIN2_PIN, stepSequence[stepIndex][3]);
  }
  
  // Getters
  int getPosition() const { return currentPosition; }
  int getTargetPosition() const { return targetPosition; }
  int getSpeed() const { return stepDelay; }
  bool getEnabled() const { return isEnabled; }
  bool getMoving() const { return isMoving; }
  bool getFault() const { return hasFault; }
  
  void clearFault() { hasFault = false; }
};
```

### BLE Callbacks
```cpp
class MotorCommandCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    uint8_t* data = pCharacteristic->getData();
    uint8_t command = data[0];
    int16_t parameter = (data[2] << 8) | data[1]; // Little endian
    
    switch(command) {
      case 0: // STOP
        motor.stop();
        break;
      case 1: // MOVE_ABSOLUTE
        motor.moveToPosition(parameter);
        break;
      case 2: // MOVE_RELATIVE
        motor.moveRelative(parameter);
        break;
      case 3: // HOME
        motor.home();
        break;
      case 4: // SET_SPEED
        motor.setSpeed(parameter);
        updateSpeedCharacteristic();
        break;
      case 5: // ENABLE
        motor.enable();
        break;
      case 6: // DISABLE
        motor.disable();
        break;
    }
    
    updateStatusCharacteristic();
  }
};

class MotorSpeedCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    uint8_t* data = pCharacteristic->getData();
    uint16_t speed = (data[1] << 8) | data[0]; // Little endian
    motor.setSpeed(speed);
  }
};
```

### Main Setup and Loop
```cpp
StepperMotor motor;

void setup() {
  Serial.begin(115200);
  
  // Initialize motor
  motor.setup();
  
  // Initialize BLE
  BLEDevice::init("ESP32 Stepper Motor");
  pServer = BLEDevice::createServer();
  pService = pServer->createService(SERVICE_UUID);
  
  // Create characteristics
  setupCharacteristics();
  
  // Start advertising
  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("ESP32 Stepper Motor Controller Ready");
}

void loop() {
  motor.update();
  updatePositionCharacteristic();
  updateStatusCharacteristic();
  delay(10);
}

void setupCharacteristics() {
  // Position Characteristic
  pPositionChar = pService->createCharacteristic(
    POSITION_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pPositionChar->addDescriptor(new BLE2902());
  
  // Command Characteristic
  pCommandChar = pService->createCharacteristic(
    COMMAND_CHAR_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  pCommandChar->setCallbacks(new MotorCommandCallbacks());
  
  // Status Characteristic
  pStatusChar = pService->createCharacteristic(
    STATUS_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pStatusChar->addDescriptor(new BLE2902());
  
  // Speed Characteristic
  pSpeedChar = pService->createCharacteristic(
    SPEED_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE
  );
  pSpeedChar->setCallbacks(new MotorSpeedCallbacks());
  
  // Limits Characteristic
  pLimitsChar = pService->createCharacteristic(
    LIMITS_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ
  );
  
  // Set initial values
  updateAllCharacteristics();
}

void updatePositionCharacteristic() {
  int16_t position = motor.getPosition();
  uint8_t data[2];
  data[0] = position & 0xFF;
  data[1] = (position >> 8) & 0xFF;
  pPositionChar->setValue(data, 2);
  pPositionChar->notify();
}

void updateStatusCharacteristic() {
  uint8_t status = 0;
  if (motor.getFault()) status = 3;
  else if (!motor.getEnabled()) status = 4;
  else if (motor.getMoving()) status = 1;
  else status = 0;
  
  uint8_t data[4];
  data[0] = status;
  data[1] = motor.getPosition() & 0xFF;
  data[2] = (motor.getPosition() >> 8) & 0xFF;
  data[3] = motor.getFault() ? 1 : 0;
  
  pStatusChar->setValue(data, 4);
  pStatusChar->notify();
}

void updateSpeedCharacteristic() {
  uint16_t speed = motor.getSpeed();
  uint8_t data[2];
  data[0] = speed & 0xFF;
  data[1] = (speed >> 8) & 0xFF;
  pSpeedChar->setValue(data, 2);
}

void updateLimitsCharacteristic() {
  uint8_t data[4];
  data[0] = MIN_POSITION & 0xFF;
  data[1] = (MIN_POSITION >> 8) & 0xFF;
  data[2] = MAX_POSITION & 0xFF;
  data[3] = (MAX_POSITION >> 8) & 0xFF;
  pLimitsChar->setValue(data, 4);
}

void updateAllCharacteristics() {
  updatePositionCharacteristic();
  updateStatusCharacteristic();
  updateSpeedCharacteristic();
  updateLimitsCharacteristic();
}
```

---

## Pin Configuration

### Available ESP32 Pins
**Total pins used:** 6 out of 30 available GPIO pins

### Motor Control Pins
- **GPIO21**: AIN1 (Phase A)
- **GPIO19**: AIN2 (Phase A)
- **GPIO16**: BIN1 (Phase B)
- **GPIO17**: BIN2 (Phase B)
- **GPIO23**: SLEEP (Enable/Disable)
- **GPIO22**: FAULT (Fault Detection)

### Reserved Pins (Do Not Use)
- **GPIO0**: Boot mode selection
- **GPIO2**: Boot mode selection / Built-in LED
- **GPIO5**: Boot mode selection
- **GPIO12**: Boot mode selection
- **GPIO15**: Boot mode selection

### Available for Expansion
- **GPIO4, 13, 14, 18, 25, 26, 27, 32, 33**: Digital I/O
- **GPIO34, 35, 36, 39**: Input only (ADC)

---

## Testing & Troubleshooting

### Basic Testing Procedure

1. **Hardware Verification**
   ```cpp
   // Test motor coils continuity
   // Measure resistance between motor wires
   // A+ to A-: Should show motor coil resistance
   // B+ to B-: Should show motor coil resistance
   // A+ to B+: Should show infinite resistance
   ```

2. **Power Supply Check**
   - ESP32: 3.3V on 3V3 pin
   - DRV8833: Input voltage on VCC pin
   - Motor: Appropriate voltage for motor specs

3. **BLE Connection Test**
   ```cpp
   // Upload code and check serial monitor
   // Should see: "ESP32 Stepper Motor Controller Ready"
   // Use BLE scanner app to find device
   // Device name: "ESP32 Stepper Motor"
   ```

4. **Motor Movement Test**
   - Connect via Flutter app
   - Send ENABLE command
   - Send small relative movement (±5 steps)
   - Verify motor rotates and position updates

### Common Issues and Solutions

#### Motor Not Moving
- **Check Power**: Verify motor power supply voltage
- **Check Wiring**: Verify all connections are correct
- **Check Enable**: Ensure motor is enabled via SLEEP pin
- **Check Steps**: Start with small movements (1-5 steps)

#### Erratic Movement
- **Power Supply**: Use stable, adequate current supply
- **Step Delay**: Increase step delay (try 50-100ms)
- **Wiring**: Check for loose connections
- **EMI**: Add capacitors near motor connections

#### BLE Connection Issues
- **Device Name**: Check if "ESP32 Stepper Motor" appears in scan
- **UUID**: Verify service UUID matches exactly
- **Range**: Ensure device is within BLE range (< 10m)
- **Reset**: Power cycle ESP32 and restart Flutter app

#### Position Drift
- **Mechanical**: Check for mechanical binding or slippage
- **Power**: Ensure adequate power supply
- **Steps**: Verify step sequence is correct
- **Homing**: Implement limit switches for accurate homing

### Debug Commands
```cpp
// Add to setup() for debugging
#define DEBUG_MODE 1

#if DEBUG_MODE
  Serial.println("Current Position: " + String(motor.getPosition()));
  Serial.println("Target Position: " + String(motor.getTargetPosition()));
  Serial.println("Enabled: " + String(motor.getEnabled()));
  Serial.println("Moving: " + String(motor.getMoving()));
  Serial.println("Fault: " + String(motor.getFault()));
#endif
```

---

## Flutter App Integration

### Connection Process
1. **Scan for Devices**: App scans for BLE devices
2. **Filter by Name**: Look for "ESP32 Stepper Motor"
3. **Connect**: Establish BLE connection
4. **Discover Services**: Find motor control service
5. **Setup Characteristics**: Subscribe to notifications
6. **Enable Motor**: Send enable command

### Supported Operations
- **Position Control**: Move to absolute position (0-200 steps)
- **Relative Movement**: Move ±N steps from current position
- **Speed Control**: Set step delay (1-1000 ms)
- **Homing**: Move to position 0
- **Enable/Disable**: Motor power control
- **Status Monitoring**: Real-time position and status
- **Fault Detection**: Monitor for hardware faults

### Flutter App Features
- **Real-time Position Display**: Shows current position in steps and mm
- **Step Controls**: ±10% buttons for easy step size adjustment
- **Motor Commands**: Home, enable/disable, stop functions
- **Status Indicators**: Visual feedback for motor state
- **Error Handling**: Connection and fault error messages

### Data Conversion
```dart
// Steps to millimeters conversion
double stepsToMm(int steps) => steps / 2.22;
int mmToSteps(double mm) => (mm * 2.22).round();

// Example: 100 steps = ~45mm movement
```

---

## Safety Considerations

### Hardware Safety
- **Power Supply**: Use appropriate voltage/current ratings
- **Heat Dissipation**: Ensure adequate cooling for motor driver
- **Mechanical Limits**: Implement limit switches to prevent over-travel
- **Emergency Stop**: Include hardware emergency stop capability

### Software Safety
- **Position Limits**: Enforce MIN_POSITION and MAX_POSITION
- **Fault Detection**: Monitor FAULT pin and stop on errors
- **Timeout**: Implement movement timeout protection
- **Gradual Acceleration**: Avoid instant high-speed movements

### Operational Safety
- **Initial Testing**: Start with slow speeds and small movements
- **Power Sequencing**: Enable motor driver before sending commands
- **Shutdown**: Properly disable motor when not in use
- **Monitoring**: Continuously monitor for faults and errors

---

## Expansion Possibilities

### Additional Features
- **Limit Switches**: Add homing and end-stop switches
- **Encoder Feedback**: Add rotary encoder for position verification
- **Multiple Motors**: Control multiple stepper motors
- **Servo Integration**: Add servo motor support
- **Sensor Input**: Add temperature, pressure, or other sensors

### Pin Assignments for Expansion
```cpp
// Available pins for additional features
#define LIMIT_SWITCH_MIN_PIN 4
#define LIMIT_SWITCH_MAX_PIN 13
#define ENCODER_A_PIN 14
#define ENCODER_B_PIN 18
#define SERVO_PIN 25
#define ANALOG_SENSOR_PIN 34
```

---

## Version History

| Version | Date | Changes |
|---|---|---|
| 1.0 | 2024-07-25 | Initial implementation |
| | | - Basic stepper motor control |
| | | - BLE service with 5 characteristics |
| | | - Flutter app integration |
| | | - Position, speed, and status monitoring |

---

## Support and Contact

For technical support or questions:
- **GitHub Issues**: Create an issue in the project repository
- **Documentation**: Refer to Flutter integration guide
- **Hardware Support**: Check DRV8833 and stepper motor datasheets

---

**Note**: This documentation assumes familiarity with Arduino IDE, ESP32 development, and basic electronics. Always follow proper safety procedures when working with electrical components.
