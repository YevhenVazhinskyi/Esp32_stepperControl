# 📱 ESP32 Stepper Motor Controller - Flutter App

A professional Flutter application for controlling ESP32-based stepper motor systems via Bluetooth Low Energy (BLE). This app provides comprehensive motor control, LED management, real-time monitoring, and advanced features for precision control systems.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![ESP32](https://img.shields.io/badge/ESP32-E7352C?style=for-the-badge&logo=espressif&logoColor=white)
![BLE](https://img.shields.io/badge/Bluetooth-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white)

## ✨ Features

### 🔗 **Advanced BLE Connection Management**
- **Auto-discovery**: Automatically scan and connect to ESP32 devices
- **Auto-reconnect**: Intelligent reconnection with exponential backoff
- **Connection monitoring**: Real-time connection health and quality metrics
- **Error recovery**: Robust error handling and recovery mechanisms

### 🎛️ **Comprehensive Motor Control**
- **Position Control**: Precise absolute and relative positioning (0-200 steps)
- **Speed Control**: Variable speed control (1-1000ms per step)
- **Real-time Feedback**: Live position updates and status monitoring
- **Jogging Controls**: Fine adjustment with configurable step sizes
- **Preset Positions**: Built-in and custom position presets
- **Movement History**: Track and analyze movement patterns
- **Emergency Stop**: Immediate motor halt functionality

### 💡 **LED Control & Patterns**
- **Individual Control**: Independent control of 4 LEDs
- **Pattern Engine**: 6 built-in animation patterns
- **Notification System**: Visual feedback for different events
- **Custom Effects**: Breathing, chase, wave, and heartbeat patterns
- **Test Functions**: Comprehensive LED testing capabilities

### 📊 **Real-time Monitoring**
- **System Status**: Complete system health monitoring
- **Performance Metrics**: Connection uptime, command statistics
- **Movement Analytics**: Position history and usage statistics
- **Error Tracking**: Comprehensive fault detection and reporting

### 🛠️ **Debug & Diagnostics**
- **Live Console**: Real-time log monitoring with filtering
- **Connection Testing**: Manual connection health checks
- **Export Capabilities**: Save logs for analysis
- **Command Interface**: Quick diagnostic commands

## 🏗️ **Architecture Overview**

### **Clean Architecture Pattern**
```
📁 lib/
├── 🎯 main.dart                    # Application entry point
├── 📱 screens/
│   └── main_screen.dart           # Tabbed main interface
├── 🎨 widgets/                    # Reusable UI components
│   ├── connection_widget.dart     # BLE connection management
│   ├── motor_control_widget.dart  # Motor control interface
│   ├── led_control_widget.dart    # LED control panel
│   ├── status_display_widget.dart # System monitoring
│   └── debug_console_widget.dart  # Debug interface
├── 🎮 controllers/               # State management (Provider)
│   ├── connection_controller.dart # BLE connection logic
│   ├── motor_controller.dart     # Motor control logic
│   └── led_controller.dart       # LED control logic
├── 🔧 services/
│   └── ble_service.dart          # BLE communication service
├── 📋 models/
│   └── motor_models.dart         # Data models and enums
└── 🛠️ utils/
    └── constants.dart            # Configuration constants
```

### **Key Design Principles**
- **Single Responsibility**: Each component has a clear, focused purpose
- **Dependency Injection**: Clean separation of concerns using Provider
- **Reactive UI**: Real-time updates using streams and state management
- **Error Boundaries**: Comprehensive error handling at every layer
- **Performance Optimized**: Efficient BLE communication and smooth animations

## 🚀 **Quick Start**

### **Prerequisites**
- Flutter SDK 3.16.0 or higher
- Dart SDK 3.2.0 or higher
- Android/iOS device with BLE support
- ESP32 device running the stepper motor firmware

### **Installation**

1. **Add Dependencies** to your `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_blue_plus: ^1.14.5
  provider: ^6.1.1
  permission_handler: ^11.2.0
  cupertino_icons: ^1.0.2
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

2. **Copy Flutter Code** to your project:
```bash
# Copy all files from this flutter/ directory to your project's lib/ directory
cp -r flutter/lib/* your_project/lib/
```

3. **Install Dependencies**:
```bash
flutter pub get
```

4. **Run the Application**:
```bash
flutter run
```

## 📋 **ESP32 Compatibility**

### **Required BLE Services**
The app expects these BLE services on your ESP32:

#### **LED Control Service** 
- Service UUID: `12345678-90ab-cdef-1234-567890abcdef`
- Characteristics:
  - LED1: `12345678-90ab-cdef-1234-567890abcd01` (Read/Write)
  - LED2: `12345678-90ab-cdef-1234-567890abcd02` (Read/Write)
  - LED3: `12345678-90ab-cdef-1234-567890abcd03` (Read/Write)
  - LED4: `12345678-90ab-cdef-1234-567890abcd04` (Read/Write)

#### **Motor Control Service**
- Service UUID: `87654321-abcd-ef90-1234-567890abcdef`
- Characteristics:
  - Position: `87654321-abcd-ef90-1234-567890abcd01` (Read/Write/Notify)
  - Command: `87654321-abcd-ef90-1234-567890abcd02` (Write)
  - Status: `87654321-abcd-ef90-1234-567890abcd03` (Read/Notify)
  - Speed: `87654321-abcd-ef90-1234-567890abcd04` (Read/Write)

### **Motor Commands Protocol**
Commands are sent as 3-byte packets: `[command:1][parameter:2]`

| Command | Value | Parameter | Description |
|---------|-------|-----------|-------------|
| STOP | 0 | 0 | Stop motor immediately |
| MOVE_ABSOLUTE | 1 | position | Move to absolute position (0-200) |
| MOVE_RELATIVE | 2 | steps | Move relative steps (-200 to +200) |
| HOME | 3 | 0 | Home motor to position 0 |
| SET_SPEED | 4 | delay_ms | Set step delay (1-1000ms) |
| ENABLE | 5 | 0 | Enable motor driver |
| DISABLE | 6 | 0 | Disable motor driver |

## 🎨 **User Interface**

### **Tab Navigation**
1. **Overview**: Quick status and essential controls
2. **Motor**: Comprehensive motor control interface
3. **LEDs**: LED control panel with patterns
4. **Status**: Detailed system monitoring
5. **Debug**: Console and diagnostic tools

### **Key UI Features**
- **Material 3 Design**: Modern, consistent visual design
- **Dark/Light Themes**: Automatic system theme adaptation
- **Responsive Layout**: Optimized for phones and tablets
- **Accessibility**: Full accessibility support
- **Smooth Animations**: 60fps performance with smooth transitions

## 🔧 **Configuration**

### **Motor Specifications** (in `constants.dart`)
```dart
static const int stepsPerRevolution = 200;     // 1.8° stepper motor
static const double threadPitchMm = 2.0;       // 2mm thread pitch
static const int maxSteps = 200;               // Maximum steps
static const int minSpeedMs = 1;               // Minimum speed (ms)
static const int maxSpeedMs = 1000;            // Maximum speed (ms)
```

### **Connection Settings**
```dart
static const Duration connectionTimeout = Duration(seconds: 10);
static const Duration scanTimeout = Duration(seconds: 15);
static const int maxReconnectAttempts = 3;
```

## 📱 **Platform Support**

### **Android**
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Required Permissions:
  - `android.permission.BLUETOOTH`
  - `android.permission.BLUETOOTH_ADMIN`
  - `android.permission.ACCESS_FINE_LOCATION`

### **iOS**
- Minimum Version: iOS 12.0
- Required Info.plist entries:
  - `NSBluetoothAlwaysUsageDescription`
  - `NSBluetoothPeripheralUsageDescription`

## 🧪 **Testing**

### **Manual Testing Checklist**
- [ ] BLE device discovery and connection
- [ ] Motor position control (absolute/relative)
- [ ] Speed adjustment and real-time updates
- [ ] LED control (individual and patterns)
- [ ] Auto-reconnect functionality
- [ ] Error handling and recovery
- [ ] Debug console and logging

### **Performance Benchmarks**
- **Connection Time**: < 3 seconds
- **Command Response**: < 100ms
- **UI Responsiveness**: 60fps
- **Memory Usage**: < 100MB
- **Battery Efficiency**: Optimized BLE usage

## 🔍 **Troubleshooting**

### **Common Issues**

#### **Connection Problems**
```
Issue: Cannot find ESP32 device
Solution: Ensure ESP32 is advertising with correct name
```

#### **Command Timeouts**
```
Issue: Motor commands not responding
Solution: Check BLE connection quality and retry
```

#### **Permission Errors**
```
Issue: Bluetooth permissions denied
Solution: Grant all required permissions in device settings
```

## 🤝 **Contributing**

### **Development Setup**
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Follow Flutter style guidelines
4. Add tests for new functionality
5. Submit pull request

### **Code Standards**
- **Dart Style Guide**: Follow official Dart conventions
- **Documentation**: Comprehensive code documentation
- **Testing**: Unit tests for all business logic
- **Performance**: Profile and optimize critical paths

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## �� **Acknowledgments**

- **Flutter Team**: For the amazing cross-platform framework
- **ESP32 Community**: For excellent hardware and documentation
- **BLE Library Authors**: For robust Bluetooth Low Energy support

---

## 📞 **Support**

For questions, issues, or contributions:

- 📧 **Email**: support@esp32controller.com
- 🐛 **Issues**: GitHub Issues
- 💬 **Discussions**: GitHub Discussions
- 📚 **Documentation**: Full API documentation available

**Built with ❤️ for precision motor control**
