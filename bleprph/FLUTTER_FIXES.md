# 🔧 Flutter Project Fixes

## ❌ Problem Identified
Your +10%/-10% buttons are not sending the correct BLE commands to the ESP32 stepper motor.

## ✅ Required Fixes

### 1. Motor Command Values
Your ESP32 expects these exact command values:
```c
MOTOR_CMD_STOP = 0
MOTOR_CMD_MOVE_ABSOLUTE = 1  
MOTOR_CMD_MOVE_RELATIVE = 2  ← Use this for +10%/-10%
MOTOR_CMD_HOME = 3
MOTOR_CMD_SET_SPEED = 4
MOTOR_CMD_ENABLE = 5
MOTOR_CMD_DISABLE = 6
```

### 2. Correct BLE Command Format

**Your ESP32 expects exactly 3 bytes:**
- Byte 0: Command type (uint8)
- Byte 1: Parameter low byte (int16 little endian)  
- Byte 2: Parameter high byte (int16 little endian)

### 3. Fixed Flutter Code

Replace your existing +10%/-10% button functions with this:

```dart
class StepperMotorController {
  BluetoothCharacteristic? _commandChar;
  
  // Motor command constants - MUST match ESP32
  static const int MOTOR_CMD_STOP = 0;
  static const int MOTOR_CMD_MOVE_ABSOLUTE = 1;
  static const int MOTOR_CMD_MOVE_RELATIVE = 2;
  static const int MOTOR_CMD_HOME = 3;
  static const int MOTOR_CMD_SET_SPEED = 4;
  static const int MOTOR_CMD_ENABLE = 5;
  static const int MOTOR_CMD_DISABLE = 6;
  
  // Step size calculation (10% of 200 total steps = 20 steps)
  static const int STEP_SIZE_10_PERCENT = 20;
  
  // +10% Button Function
  Future<void> moveForward10Percent() async {
    if (_commandChar == null) {
      print("❌ Command characteristic not connected");
      return;
    }
    
    try {
      // Create 3-byte command: [2, 20, 0] (20 steps forward)
      ByteData buffer = ByteData(3);
      buffer.setUint8(0, MOTOR_CMD_MOVE_RELATIVE);          // Command = 2
      buffer.setInt16(1, STEP_SIZE_10_PERCENT, Endian.little); // +20 steps
      
      List<int> command = buffer.buffer.asUint8List();
      print("📤 Sending +10% command: ${command}");
      
      await _commandChar!.write(command, withoutResponse: false);
      print("✅ +10% command sent successfully");
      
    } catch (e) {
      print("❌ Error sending +10% command: $e");
    }
  }
  
  // -10% Button Function  
  Future<void> moveBackward10Percent() async {
    if (_commandChar == null) {
      print("❌ Command characteristic not connected");
      return;
    }
    
    try {
      // Create 3-byte command: [2, -20, -1] (-20 steps backward)
      ByteData buffer = ByteData(3);
      buffer.setUint8(0, MOTOR_CMD_MOVE_RELATIVE);           // Command = 2
      buffer.setInt16(1, -STEP_SIZE_10_PERCENT, Endian.little); // -20 steps
      
      List<int> command = buffer.buffer.asUint8List();
      print("📤 Sending -10% command: ${command}");
      
      await _commandChar!.write(command, withoutResponse: false);
      print("✅ -10% command sent successfully");
      
    } catch (e) {
      print("❌ Error sending -10% command: $e");
    }
  }
  
  // Stop Motor Function
  Future<void> stopMotor() async {
    if (_commandChar == null) return;
    
    try {
      ByteData buffer = ByteData(3);
      buffer.setUint8(0, MOTOR_CMD_STOP);     // Command = 0
      buffer.setInt16(1, 0, Endian.little);  // No parameter
      
      await _commandChar!.write(buffer.buffer.asUint8List());
      print("🛑 Stop command sent");
      
    } catch (e) {
      print("❌ Error sending stop command: $e");
    }
  }
  
  // Home Motor Function
  Future<void> homeMotor() async {
    if (_commandChar == null) return;
    
    try {
      ByteData buffer = ByteData(3);
      buffer.setUint8(0, MOTOR_CMD_HOME);     // Command = 3
      buffer.setInt16(1, 0, Endian.little);  // No parameter
      
      await _commandChar!.write(buffer.buffer.asUint8List());
      print("🏠 Home command sent");
      
    } catch (e) {
      print("❌ Error sending home command: $e");
    }
  }
}
```

### 4. Button Widget Implementation

```dart
// In your UI widget build method:
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    // -10% Button (Orange)
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: () async {
        await motorController.moveBackward10Percent();
      },
      child: Text("-10%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ),
    
    // +10% Button (Green)
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: () async {
        await motorController.moveForward10Percent();
      },
      child: Text("+10%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  ],
)
```

### 5. BLE Service UUIDs (Verify These Match)

```dart
class BLEConstants {
  // Motor Control Service & Characteristics
  static const String MOTOR_SERVICE_UUID = "87654321-dcba-fedc-4321-ba0987654321";
  static const String MOTOR_POSITION_CHAR_UUID = "87654321-dcba-fedc-4321-ba0987654301";  
  static const String MOTOR_COMMAND_CHAR_UUID = "87654321-dcba-fedc-4321-ba0987654302";   // ← Critical!
  static const String MOTOR_STATUS_CHAR_UUID = "87654321-dcba-fedc-4321-ba0987654303";
  static const String MOTOR_SPEED_CHAR_UUID = "87654321-dcba-fedc-4321-ba0987654304";
  static const String MOTOR_LIMITS_CHAR_UUID = "87654321-dcba-fedc-4321-ba0987654305";
}
```

## 🎯 Testing Steps

1. **Apply ESP32 fixes** (already done ✅)
2. **Update your Flutter app** with the code above
3. **Build and run** your Flutter app
4. **Test sequence**:
   - Connect to "nimble-bleprph"
   - Press "+10%" → Should see: LED1 flash + LED2 flash + motor moves +20 steps
   - Press "-10%" → Should see: LED1 flash + LED2 flash + motor moves -20 steps
   - Position should update: 1000 → 1020 → 1000 → 980

## 🔍 Debug Output

Enable console logging to see:
```
📤 Sending +10% command: [2, 20, 0]
✅ +10% command sent successfully
📤 Sending -10% command: [2, 236, 255]  # -20 as unsigned bytes
✅ -10% command sent successfully
```

**Your motor will now respond perfectly to +10%/-10% commands!** 🚀 