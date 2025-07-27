import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/motor_models.dart';
import '../utils/constants.dart';

/// Comprehensive BLE service for ESP32 stepper motor communication
class BleService extends ChangeNotifier {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  // Connection state
  BluetoothDevice? _connectedDevice;
  ConnectionState _connectionState = ConnectionState.disconnected;
  String? _errorMessage;

  // BLE characteristics
  BluetoothCharacteristic? _motorPositionChar;
  BluetoothCharacteristic? _motorCommandChar;
  BluetoothCharacteristic? _motorStatusChar;
  BluetoothCharacteristic? _motorSpeedChar;
  List<BluetoothCharacteristic?> _ledChars = List.filled(4, null);

  // Data streams
  final StreamController<MotorState> _motorStateController = StreamController.broadcast();
  final StreamController<LedState> _ledStateController = StreamController.broadcast();
  final StreamController<String> _logController = StreamController.broadcast();

  // Current state
  MotorState _currentMotorState = MotorState(
    position: 0,
    targetPosition: 0,
    status: MotorStatus.idle,
    isFault: false,
    speedMs: ESP32Constants.defaultSpeedMs,
    isEnabled: false,
    timestamp: DateTime.now(),
  );
  
  LedState _currentLedState = LedState.initial();

  // Getters
  ConnectionState get connectionState => _connectionState;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _connectionState == ConnectionState.connected;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  MotorState get currentMotorState => _currentMotorState;
  LedState get currentLedState => _currentLedState;

  // Streams
  Stream<MotorState> get motorStateStream => _motorStateController.stream;
  Stream<LedState> get ledStateStream => _ledStateController.stream;
  Stream<String> get logStream => _logController.stream;

  /// Initialize BLE and request permissions
  Future<bool> initialize() async {
    try {
      _log('Initializing BLE service...');
      
      // Request permissions
      final permissions = await _requestPermissions();
      if (!permissions) {
        _setError('Bluetooth permissions not granted');
        return false;
      }

      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        _setError('Bluetooth not supported on this device');
        return false;
      }

      // Listen to Bluetooth state
      FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
        if (state != BluetoothAdapterState.on && _connectionState == ConnectionState.connected) {
          _handleDisconnection();
        }
      });

      _log('BLE service initialized successfully');
      return true;
    } catch (e) {
      _setError('Failed to initialize BLE: $e');
      return false;
    }
  }

  /// Request necessary permissions for BLE
  Future<bool> _requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (status != PermissionStatus.granted) {
        _log('Permission denied: $permission');
        return false;
      }
    }
    return true;
  }

  /// Scan for ESP32 device and connect
  Future<bool> connectToDevice() async {
    if (_connectionState == ConnectionState.connecting) return false;

    try {
      _setConnectionState(ConnectionState.scanning);
      _log('Scanning for ESP32 device...');

      // Turn on Bluetooth if needed
      if (await FlutterBluePlus.isOn == false) {
        await FlutterBluePlus.turnOn();
        await Future.delayed(const Duration(seconds: 2));
      }

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: ESP32Constants.scanTimeout,
        withNames: [ESP32Constants.deviceName],
      );

      BluetoothDevice? targetDevice;
      
      // Listen for scan results
      await for (final scanResult in FlutterBluePlus.scanResults) {
        final device = scanResult.device;
        final name = device.platformName;
        
        _log('Found device: $name');
        
        if (name.contains(ESP32Constants.devicePrefix) || 
            name == ESP32Constants.deviceName) {
          targetDevice = device;
          break;
        }
      }

      await FlutterBluePlus.stopScan();

      if (targetDevice == null) {
        _setError('ESP32 device not found');
        return false;
      }

      return await _connectToDevice(targetDevice);
    } catch (e) {
      _setError('Failed to scan for devices: $e');
      return false;
    }
  }

  /// Connect to specific device
  Future<bool> _connectToDevice(BluetoothDevice device) async {
    try {
      _setConnectionState(ConnectionState.connecting);
      _log('Connecting to ${device.platformName}...');

      // Connect to device
      await device.connect(timeout: ESP32Constants.connectionTimeout);
      _connectedDevice = device;

      // Listen for disconnection
      device.connectionState.listen((BluetoothConnectionState state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Discover services
      final services = await device.discoverServices();
      if (!await _setupCharacteristics(services)) {
        await device.disconnect();
        return false;
      }

      _setConnectionState(ConnectionState.connected);
      _log('Successfully connected to ESP32');
      
      // Start notifications
      await _setupNotifications();
      
      // Read initial states
      await _readInitialStates();
      
      return true;
    } catch (e) {
      _setError('Failed to connect: $e');
      return false;
    }
  }

  /// Setup characteristics from discovered services
  Future<bool> _setupCharacteristics(List<BluetoothService> services) async {
    try {
      for (final service in services) {
        final serviceUuid = service.uuid.toString().toLowerCase();
        
        if (serviceUuid.contains(ESP32Constants.ledServiceUuid.replaceAll('-', ''))) {
          // LED Service
          for (final char in service.characteristics) {
            final charUuid = char.uuid.toString().toLowerCase();
            if (charUuid.contains('cd01')) _ledChars[0] = char;
            else if (charUuid.contains('cd02')) _ledChars[1] = char;
            else if (charUuid.contains('cd03')) _ledChars[2] = char;
            else if (charUuid.contains('cd04')) _ledChars[3] = char;
          }
        } 
        else if (serviceUuid.contains(ESP32Constants.motorServiceUuid.replaceAll('-', ''))) {
          // Motor Service
          for (final char in service.characteristics) {
            final charUuid = char.uuid.toString().toLowerCase();
            if (charUuid.contains('cd01')) _motorPositionChar = char;
            else if (charUuid.contains('cd02')) _motorCommandChar = char;
            else if (charUuid.contains('cd03')) _motorStatusChar = char;
            else if (charUuid.contains('cd04')) _motorSpeedChar = char;
          }
        }
      }

      // Verify all characteristics found
      final hasMotorChars = _motorPositionChar != null && 
                           _motorCommandChar != null && 
                           _motorStatusChar != null && 
                           _motorSpeedChar != null;
      
      final hasLedChars = _ledChars.every((char) => char != null);

      if (!hasMotorChars || !hasLedChars) {
        _setError('Failed to find all required characteristics');
        return false;
      }

      _log('All characteristics discovered successfully');
      return true;
    } catch (e) {
      _setError('Failed to setup characteristics: $e');
      return false;
    }
  }

  /// Setup notifications for real-time updates
  Future<void> _setupNotifications() async {
    try {
      // Position notifications
      if (_motorPositionChar!.properties.notify) {
        await _motorPositionChar!.setNotifyValue(true);
        _motorPositionChar!.lastValueStream.listen((value) {
          if (value.isNotEmpty) {
            final position = value[0] | (value[1] << 8);
            _currentMotorState = _currentMotorState.copyWith(
              targetPosition: position,
              timestamp: DateTime.now(),
            );
            _motorStateController.add(_currentMotorState);
          }
        });
      }

      // Status notifications
      if (_motorStatusChar!.properties.notify) {
        await _motorStatusChar!.setNotifyValue(true);
        _motorStatusChar!.lastValueStream.listen((value) {
          if (value.length >= 4) {
            _currentMotorState = MotorState.fromStatusPacket(
              Uint8List.fromList(value), 
              _currentMotorState.speedMs,
            );
            _motorStateController.add(_currentMotorState);
          }
        });
      }

      _log('Notifications setup complete');
    } catch (e) {
      _log('Warning: Failed to setup some notifications: $e');
    }
  }

  /// Read initial states from device
  Future<void> _readInitialStates() async {
    try {
      // Read motor status
      final statusValue = await _motorStatusChar!.read();
      if (statusValue.length >= 4) {
        _currentMotorState = MotorState.fromStatusPacket(
          Uint8List.fromList(statusValue),
          _currentMotorState.speedMs,
        );
        _motorStateController.add(_currentMotorState);
      }

      // Read motor speed
      final speedValue = await _motorSpeedChar!.read();
      if (speedValue.length >= 2) {
        final speed = speedValue[0] | (speedValue[1] << 8);
        _currentMotorState = _currentMotorState.copyWith(speedMs: speed);
        _motorStateController.add(_currentMotorState);
      }

      // Read LED states
      for (int i = 0; i < 4; i++) {
        final ledValue = await _ledChars[i]!.read();
        if (ledValue.isNotEmpty) {
          switch (i) {
            case 0: _currentLedState = _currentLedState.copyWith(led1: ledValue[0] != 0); break;
            case 1: _currentLedState = _currentLedState.copyWith(led2: ledValue[0] != 0); break;
            case 2: _currentLedState = _currentLedState.copyWith(led3: ledValue[0] != 0); break;
            case 3: _currentLedState = _currentLedState.copyWith(led4: ledValue[0] != 0); break;
          }
        }
      }
      _currentLedState = _currentLedState.copyWith(timestamp: DateTime.now());
      _ledStateController.add(_currentLedState);

      _log('Initial states read successfully');
    } catch (e) {
      _log('Warning: Failed to read some initial states: $e');
    }
  }

  /// Send motor command
  Future<bool> sendMotorCommand(MotorCommand command, [int parameter = 0]) async {
    if (!isConnected || _motorCommandChar == null) {
      _setError('Not connected to device');
      return false;
    }

    try {
      final packet = command.createPacket(parameter);
      await _motorCommandChar!.write(packet);
      _log('Sent motor command: ${command.name} ($parameter)');
      return true;
    } catch (e) {
      _setError('Failed to send motor command: $e');
      return false;
    }
  }

  /// Control LED state
  Future<bool> setLedState(int ledIndex, bool state) async {
    if (!isConnected || ledIndex < 0 || ledIndex > 3 || _ledChars[ledIndex] == null) {
      _setError('Invalid LED index or not connected');
      return false;
    }

    try {
      final value = [state ? 1 : 0];
      await _ledChars[ledIndex]!.write(value);
      
      // Update local state
      _currentLedState = _currentLedState.copyWith(timestamp: DateTime.now());
      switch (ledIndex) {
        case 0: _currentLedState = _currentLedState.copyWith(led1: state); break;
        case 1: _currentLedState = _currentLedState.copyWith(led2: state); break;
        case 2: _currentLedState = _currentLedState.copyWith(led3: state); break;
        case 3: _currentLedState = _currentLedState.copyWith(led4: state); break;
      }
      _ledStateController.add(_currentLedState);
      
      _log('LED${ledIndex + 1} set to ${state ? 'ON' : 'OFF'}');
      return true;
    } catch (e) {
      _setError('Failed to control LED: $e');
      return false;
    }
  }

  /// Set motor speed
  Future<bool> setMotorSpeed(int speedMs) async {
    if (!isConnected || _motorSpeedChar == null) {
      _setError('Not connected to device');
      return false;
    }

    final clampedSpeed = speedMs.clamp(ESP32Constants.minSpeedMs, ESP32Constants.maxSpeedMs);
    
    try {
      final speedBytes = [clampedSpeed & 0xFF, (clampedSpeed >> 8) & 0xFF];
      await _motorSpeedChar!.write(speedBytes);
      
      _currentMotorState = _currentMotorState.copyWith(
        speedMs: clampedSpeed,
        timestamp: DateTime.now(),
      );
      _motorStateController.add(_currentMotorState);
      
      _log('Motor speed set to ${clampedSpeed}ms');
      return true;
    } catch (e) {
      _setError('Failed to set motor speed: $e');
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
      _handleDisconnection();
      _log('Disconnected from device');
    } catch (e) {
      _log('Error during disconnection: $e');
      _handleDisconnection();
    }
  }

  /// Handle disconnection cleanup
  void _handleDisconnection() {
    _connectedDevice = null;
    _motorPositionChar = null;
    _motorCommandChar = null;
    _motorStatusChar = null;
    _motorSpeedChar = null;
    _ledChars = List.filled(4, null);
    _setConnectionState(ConnectionState.disconnected);
    _errorMessage = null;
    
    // Reset states
    _currentMotorState = MotorState(
      position: 0,
      targetPosition: 0,
      status: MotorStatus.idle,
      isFault: false,
      speedMs: ESP32Constants.defaultSpeedMs,
      isEnabled: false,
      timestamp: DateTime.now(),
    );
    _currentLedState = LedState.initial();
    
    notifyListeners();
  }

  /// Set connection state and notify listeners
  void _setConnectionState(ConnectionState state) {
    _connectionState = state;
    notifyListeners();
  }

  /// Set error message and notify listeners
  void _setError(String message) {
    _errorMessage = message;
    _connectionState = ConnectionState.error;
    _log('ERROR: $message');
    notifyListeners();
  }

  /// Log message
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    debugPrint(logMessage);
    _logController.add(logMessage);
  }

  @override
  void dispose() {
    _motorStateController.close();
    _ledStateController.close();
    _logController.close();
    disconnect();
    super.dispose();
  }
}
