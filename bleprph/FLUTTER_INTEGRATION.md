# ESP32 Stepper Motor BLE Integration - Flutter Guide

## Overview

This document provides complete integration guidelines for controlling a 2-phase 4-wire stepper motor (90mm stroke, 18° step angle) via Bluetooth Low Energy (BLE) from a Flutter mobile application.

## Hardware Setup

### ESP32 to DRV8833 Connections
```
ESP32 GPIO21 → DRV8833 AIN1   (Motor Phase A Control)
ESP32 GPIO19 → DRV8833 AIN2   (Motor Phase A Control)
ESP32 GPIO16 → DRV8833 BIN1   (Motor Phase B Control)
ESP32 GPIO17 → DRV8833 BIN2   (Motor Phase B Control)
ESP32 GPIO23 → DRV8833 SLEEP  (Driver Enable/Disable)
ESP32 GPIO22 → DRV8833 FAULT  (Fault Detection Input)
```

### Motor Wire to DRV8833 Connections
```
Blue Wire (A+)   → DRV8833 AOUT1
Black Wire (A-)  → DRV8833 AOUT2  
Red Wire (B+)    → DRV8833 BOUT1
Yellow Wire (B-) → DRV8833 BOUT2
```

### Pin Usage Summary
**Total pins used:** 10 out of 30 available  
**Motor control:** 6 pins  
**LED control:** 4 pins (GPIO2, 4, 5, 18)  
**Available for expansion:** 20 pins

> **📋 Note**: See `PIN_MAPPING.md` for complete pin assignments and expansion possibilities

### Motor Specifications
- **Step Angle**: 18 degrees (20 steps per full rotation)
- **Stroke Length**: 90mm
- **Steps per mm**: ~2.22 (depends on lead screw pitch)
- **Max Position**: ~200 steps (90mm × 2.22)

## BLE Service Structure

### Service UUID
```
Motor Control Service: 87654321-dcba-fedc-4321-ba0987654321
```

### Characteristics

#### 1. Motor Position (Read/Write/Notify)
- **UUID**: `87654321-dcba-fedc-4321-ba0987654301`
- **Type**: `int16` (2 bytes, little endian)
- **Range**: 0 to 200 steps
- **Purpose**: Get/set absolute motor position
- **Notifications**: Position updates during movement

#### 2. Motor Command (Write Only)
- **UUID**: `87654321-dcba-fedc-4321-ba0987654302`
- **Format**: 3 bytes `[command:1][parameter:2]`
- **Purpose**: Send motor control commands

**Command Types:**
```dart
enum MotorCommand {
  stop(0),
  moveAbsolute(1),
  moveRelative(2),
  home(3),
  setSpeed(4),
  enable(5),
  disable(6);
}
```

#### 3. Motor Status (Read/Notify)
- **UUID**: `87654321-dcba-fedc-4321-ba0987654303`
- **Format**: 4 bytes `[status:1][position:2][fault:1]`
- **Purpose**: Get motor status and fault information

**Status Values:**
```dart
enum MotorStatus {
  idle(0),
  moving(1),
  homing(2),
  error(3),
  disabled(4);
}
```

#### 4. Motor Speed (Read/Write)
- **UUID**: `87654321-dcba-fedc-4321-ba0987654304`
- **Type**: `uint16` (2 bytes, little endian)
- **Range**: 1-1000 ms (delay between steps)
- **Purpose**: Control motor speed

#### 5. Motor Limits (Read Only)
- **UUID**: `87654321-dcba-fedc-4321-ba0987654305`
- **Format**: 4 bytes `[min_pos:2][max_pos:2]`
- **Purpose**: Get position limits

## Flutter Implementation

### Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_blue_plus: ^1.17.1
```

### BLE Service Class

```dart
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class StepperMotorService {
  static const String SERVICE_UUID = "87654321-dcba-fedc-4321-ba0987654321";
  static const String POSITION_CHAR_UUID = "87654321-dcba-fedc-4321-ba0987654301";
  static const String COMMAND_CHAR_UUID = "87654321-dcba-fedc-4321-ba0987654302";
  static const String STATUS_CHAR_UUID = "87654321-dcba-fedc-4321-ba0987654303";
  static const String SPEED_CHAR_UUID = "87654321-dcba-fedc-4321-ba0987654304";
  static const String LIMITS_CHAR_UUID = "87654321-dcba-fedc-4321-ba0987654305";

  BluetoothDevice? _device;
  BluetoothCharacteristic? _positionChar;
  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _speedChar;
  BluetoothCharacteristic? _limitsChar;

  Stream<int>? _positionStream;
  Stream<MotorStatusData>? _statusStream;

  // Connect to ESP32 device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      _device = device;
      await device.connect();
      
      List<BluetoothService> services = await device.discoverServices();
      BluetoothService? motorService = services.firstWhere(
        (service) => service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase(),
      );

      if (motorService == null) return false;

      // Get characteristics
      _positionChar = motorService.characteristics.firstWhere(
        (char) => char.uuid.toString().toLowerCase() == POSITION_CHAR_UUID.toLowerCase(),
      );
      
      _commandChar = motorService.characteristics.firstWhere(
        (char) => char.uuid.toString().toLowerCase() == COMMAND_CHAR_UUID.toLowerCase(),
      );
      
      _statusChar = motorService.characteristics.firstWhere(
        (char) => char.uuid.toString().toLowerCase() == STATUS_CHAR_UUID.toLowerCase(),
      );
      
      _speedChar = motorService.characteristics.firstWhere(
        (char) => char.uuid.toString().toLowerCase() == SPEED_CHAR_UUID.toLowerCase(),
      );
      
      _limitsChar = motorService.characteristics.firstWhere(
        (char) => char.uuid.toString().toLowerCase() == LIMITS_CHAR_UUID.toLowerCase(),
      );

      // Enable notifications
      await _positionChar?.setNotifyValue(true);
      await _statusChar?.setNotifyValue(true);

      // Setup streams
      _positionStream = _positionChar?.onValueReceived.map((data) => 
        ByteData.sublistView(Uint8List.fromList(data)).getInt16(0, Endian.little)
      );
      
      _statusStream = _statusChar?.onValueReceived.map((data) => 
        MotorStatusData.fromBytes(data)
      );

      return true;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }

  // Disconnect from device
  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
  }

  // Get current position
  Future<int?> getPosition() async {
    if (_positionChar == null) return null;
    
    List<int> data = await _positionChar!.read();
    return ByteData.sublistView(Uint8List.fromList(data)).getInt16(0, Endian.little);
  }

  // Move to absolute position
  Future<void> moveToPosition(int position) async {
    if (_commandChar == null) return;
    
    ByteData buffer = ByteData(3);
    buffer.setUint8(0, MotorCommand.moveAbsolute.value);
    buffer.setInt16(1, position, Endian.little);
    
    await _commandChar!.write(buffer.buffer.asUint8List());
  }

  // Move relative steps
  Future<void> moveRelative(int steps) async {
    if (_commandChar == null) return;
    
    ByteData buffer = ByteData(3);
    buffer.setUint8(0, MotorCommand.moveRelative.value);
    buffer.setInt16(1, steps, Endian.little);
    
    await _commandChar!.write(buffer.buffer.asUint8List());
  }

  // Home motor
  Future<void> home() async {
    if (_commandChar == null) return;
    
    ByteData buffer = ByteData(3);
    buffer.setUint8(0, MotorCommand.home.value);
    buffer.setInt16(1, 0, Endian.little);
    
    await _commandChar!.write(buffer.buffer.asUint8List());
  }

  // Stop motor
  Future<void> stop() async {
    if (_commandChar == null) return;
    
    ByteData buffer = ByteData(3);
    buffer.setUint8(0, MotorCommand.stop.value);
    buffer.setInt16(1, 0, Endian.little);
    
    await _commandChar!.write(buffer.buffer.asUint8List());
  }

  // Set motor speed
  Future<void> setSpeed(int speedDelayMs) async {
    if (_speedChar == null) return;
    
    ByteData buffer = ByteData(2);
    buffer.setUint16(0, speedDelayMs, Endian.little);
    
    await _speedChar!.write(buffer.buffer.asUint8List());
  }

  // Get motor speed
  Future<int?> getSpeed() async {
    if (_speedChar == null) return null;
    
    List<int> data = await _speedChar!.read();
    return ByteData.sublistView(Uint8List.fromList(data)).getUint16(0, Endian.little);
  }

  // Enable motor
  Future<void> enable() async {
    if (_commandChar == null) return;
    
    ByteData buffer = ByteData(3);
    buffer.setUint8(0, MotorCommand.enable.value);
    buffer.setInt16(1, 0, Endian.little);
    
    await _commandChar!.write(buffer.buffer.asUint8List());
  }

  // Disable motor
  Future<void> disable() async {
    if (_commandChar == null) return;
    
    ByteData buffer = ByteData(3);
    buffer.setUint8(0, MotorCommand.disable.value);
    buffer.setInt16(1, 0, Endian.little);
    
    await _commandChar!.write(buffer.buffer.asUint8List());
  }

  // Get motor status
  Future<MotorStatusData?> getStatus() async {
    if (_statusChar == null) return null;
    
    List<int> data = await _statusChar!.read();
    return MotorStatusData.fromBytes(data);
  }

  // Get motor limits
  Future<MotorLimits?> getLimits() async {
    if (_limitsChar == null) return null;
    
    List<int> data = await _limitsChar!.read();
    ByteData buffer = ByteData.sublistView(Uint8List.fromList(data));
    
    return MotorLimits(
      minPosition: buffer.getInt16(0, Endian.little),
      maxPosition: buffer.getInt16(2, Endian.little),
    );
  }

  // Streams
  Stream<int>? get positionStream => _positionStream;
  Stream<MotorStatusData>? get statusStream => _statusStream;
  
  bool get isConnected => _device?.isConnected ?? false;
}

// Enums and Data Classes
enum MotorCommand {
  stop(0),
  moveAbsolute(1),
  moveRelative(2),
  home(3),
  setSpeed(4),
  enable(5),
  disable(6);
  
  const MotorCommand(this.value);
  final int value;
}

enum MotorStatus {
  idle(0),
  moving(1),
  homing(2),
  error(3),
  disabled(4);
  
  const MotorStatus(this.value);
  final int value;
  
  static MotorStatus fromValue(int value) {
    return MotorStatus.values.firstWhere((status) => status.value == value);
  }
}

class MotorStatusData {
  final MotorStatus status;
  final int position;
  final bool isFault;
  
  MotorStatusData({
    required this.status,
    required this.position,
    required this.isFault,
  });
  
  static MotorStatusData fromBytes(List<int> data) {
    ByteData buffer = ByteData.sublistView(Uint8List.fromList(data));
    
    return MotorStatusData(
      status: MotorStatus.fromValue(buffer.getUint8(0)),
      position: buffer.getInt16(1, Endian.little),
      isFault: buffer.getUint8(3) == 1,
    );
  }
}

class MotorLimits {
  final int minPosition;
  final int maxPosition;
  
  MotorLimits({
    required this.minPosition,
    required this.maxPosition,
  });
}
```

### UI Controller Class

```dart
import 'package:flutter/material.dart';
import 'dart:async';

class MotorController extends ChangeNotifier {
  final StepperMotorService _motorService = StepperMotorService();
  
  int _currentPosition = 0;
  MotorStatus _currentStatus = MotorStatus.idle;
  int _currentSpeed = 10;
  bool _isFault = false;
  MotorLimits? _limits;
  
  StreamSubscription? _positionSubscription;
  StreamSubscription? _statusSubscription;

  // Getters
  int get currentPosition => _currentPosition;
  MotorStatus get currentStatus => _currentStatus;
  int get currentSpeed => _currentSpeed;
  bool get isFault => _isFault;
  MotorLimits? get limits => _limits;
  bool get isConnected => _motorService.isConnected;

  // Connect to motor
  Future<bool> connect(BluetoothDevice device) async {
    bool success = await _motorService.connect(device);
    
    if (success) {
      // Setup listeners
      _positionSubscription = _motorService.positionStream?.listen((position) {
        _currentPosition = position;
        notifyListeners();
      });
      
      _statusSubscription = _motorService.statusStream?.listen((statusData) {
        _currentStatus = statusData.status;
        _currentPosition = statusData.position;
        _isFault = statusData.isFault;
        notifyListeners();
      });
      
      // Get initial values
      await _refreshStatus();
    }
    
    return success;
  }

  // Disconnect from motor
  Future<void> disconnect() async {
    await _positionSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _motorService.disconnect();
    notifyListeners();
  }

  // Refresh status
  Future<void> _refreshStatus() async {
    try {
      final position = await _motorService.getPosition();
      final status = await _motorService.getStatus();
      final speed = await _motorService.getSpeed();
      final limits = await _motorService.getLimits();
      
      if (position != null) _currentPosition = position;
      if (status != null) {
        _currentStatus = status.status;
        _isFault = status.isFault;
      }
      if (speed != null) _currentSpeed = speed;
      if (limits != null) _limits = limits;
      
      notifyListeners();
    } catch (e) {
      print('Error refreshing status: $e');
    }
  }

  // Motor control methods
  Future<void> moveToPosition(int position) async {
    await _motorService.moveToPosition(position);
  }

  Future<void> moveRelative(int steps) async {
    await _motorService.moveRelative(steps);
  }

  Future<void> home() async {
    await _motorService.home();
  }

  Future<void> stop() async {
    await _motorService.stop();
  }

  Future<void> setSpeed(int speedDelayMs) async {
    await _motorService.setSpeed(speedDelayMs);
    _currentSpeed = speedDelayMs;
    notifyListeners();
  }

  Future<void> enable() async {
    await _motorService.enable();
  }

  Future<void> disable() async {
    await _motorService.disable();
  }

  // Convert position to millimeters
  double positionToMm(int steps) {
    return steps / 2.22; // Approximate conversion
  }

  // Convert millimeters to position
  int mmToPosition(double mm) {
    return (mm * 2.22).round();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
```

### Example UI Widget

```dart
class MotorControlWidget extends StatefulWidget {
  final MotorController controller;

  const MotorControlWidget({Key? key, required this.controller}) : super(key: key);

  @override
  _MotorControlWidgetState createState() => _MotorControlWidgetState();
}

class _MotorControlWidgetState extends State<MotorControlWidget> {
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _speedController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Column(
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Motor Status', style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Position:'),
                        Text('${widget.controller.currentPosition} steps (${widget.controller.positionToMm(widget.controller.currentPosition).toStringAsFixed(1)} mm)'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status:'),
                        Text(widget.controller.currentStatus.name.toUpperCase()),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Speed:'),
                        Text('${widget.controller.currentSpeed} ms/step'),
                      ],
                    ),
                    if (widget.controller.isFault)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('FAULT DETECTED', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
            
            // Position Control
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Position Control', style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _positionController,
                            decoration: InputDecoration(
                              labelText: 'Target Position (steps)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            int? position = int.tryParse(_positionController.text);
                            if (position != null) {
                              widget.controller.moveToPosition(position);
                            }
                          },
                          child: Text('Move'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => widget.controller.moveRelative(-10),
                          child: Text('← 10'),
                        ),
                        ElevatedButton(
                          onPressed: () => widget.controller.moveRelative(-1),
                          child: Text('← 1'),
                        ),
                        ElevatedButton(
                          onPressed: () => widget.controller.stop(),
                          child: Text('STOP'),
                        ),
                        ElevatedButton(
                          onPressed: () => widget.controller.moveRelative(1),
                          child: Text('1 →'),
                        ),
                        ElevatedButton(
                          onPressed: () => widget.controller.moveRelative(10),
                          child: Text('10 →'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Speed and Control
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Motor Control', style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _speedController,
                            decoration: InputDecoration(
                              labelText: 'Speed (ms/step)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            int? speed = int.tryParse(_speedController.text);
                            if (speed != null && speed > 0) {
                              widget.controller.setSpeed(speed);
                            }
                          },
                          child: Text('Set Speed'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => widget.controller.home(),
                          child: Text('Home'),
                        ),
                        ElevatedButton(
                          onPressed: () => widget.controller.enable(),
                          child: Text('Enable'),
                        ),
                        ElevatedButton(
                          onPressed: () => widget.controller.disable(),
                          child: Text('Disable'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
```

## Usage Example

```dart
class MotorControlPage extends StatefulWidget {
  @override
  _MotorControlPageState createState() => _MotorControlPageState();
}

class _MotorControlPageState extends State<MotorControlPage> {
  final MotorController _motorController = MotorController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stepper Motor Control')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: MotorControlWidget(controller: _motorController),
      ),
    );
  }
  
  @override
  void dispose() {
    _motorController.dispose();
    super.dispose();
  }
}
```

## Integration Notes

1. **Permissions**: Add Bluetooth permissions to `android/app/src/main/AndroidManifest.xml`
2. **Device Discovery**: Use `FlutterBluePlus.scanResults` to find ESP32 device
3. **Error Handling**: Implement proper error handling for BLE operations
4. **Position Tracking**: Use notifications for real-time position updates
5. **Speed Control**: Lower values = faster movement (1ms = very fast, 100ms = slow)
6. **Safety**: Always check limits before sending position commands
7. **Power Management**: Use enable/disable to save power when not in use

## Troubleshooting

- **Connection Issues**: Ensure ESP32 is advertising and in range
- **Command Not Working**: Check BLE characteristic write permissions
- **Position Inaccurate**: Calibrate steps-per-mm value for your lead screw
- **Motor Stalls**: Increase speed delay or check motor power supply
- **Fault Detection**: Monitor fault pin and implement proper error recovery 