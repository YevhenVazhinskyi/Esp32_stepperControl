import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/motor_models.dart';
import '../services/ble_service.dart';
import '../utils/constants.dart';

/// Connection management with auto-reconnect and monitoring
class ConnectionController extends ChangeNotifier {
  final BleService _bleService = BleService();
  
  // Connection state
  ConnectionState _connectionState = ConnectionState.disconnected;
  String? _errorMessage;
  String? _connectedDeviceName;
  DateTime? _connectionTime;
  Duration _connectionDuration = Duration.zero;
  
  // Auto-reconnect
  bool _autoReconnectEnabled = true;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _connectionTimer;
  
  // Connection monitoring
  Timer? _monitoringTimer;
  List<String> _connectionLog = [];

  // Getters
  ConnectionState get connectionState => _connectionState;
  String? get errorMessage => _errorMessage;
  String? get connectedDeviceName => _connectedDeviceName;
  DateTime? get connectionTime => _connectionTime;
  Duration get connectionDuration => _connectionDuration;
  bool get autoReconnectEnabled => _autoReconnectEnabled;
  int get reconnectAttempts => _reconnectAttempts;
  List<String> get connectionLog => List.unmodifiable(_connectionLog);
  
  // Computed properties
  bool get isConnected => _connectionState == ConnectionState.connected;
  bool get isConnecting => _connectionState == ConnectionState.connecting || 
                          _connectionState == ConnectionState.scanning;
  bool get canConnect => _connectionState == ConnectionState.disconnected;
  bool get hasError => _connectionState == ConnectionState.error;

  ConnectionController() {
    _initController();
  }

  /// Initialize connection controller
  Future<void> _initController() async {
    // Initialize BLE service
    await _bleService.initialize();
    
    // Listen to connection state changes from BLE service
    _bleService.addListener(_onBleStateChanged);
    
    // Listen to log messages
    _bleService.logStream.listen((message) {
      _addToLog(message);
    });
    
    // Start connection monitoring
    _startMonitoring();
  }

  /// Handle BLE service state changes
  void _onBleStateChanged() {
    final newState = _bleService.connectionState;
    final newError = _bleService.errorMessage;
    
    if (newState != _connectionState) {
      _updateConnectionState(newState, newError);
    }
  }

  /// Update connection state and handle transitions
  void _updateConnectionState(ConnectionState newState, String? error) {
    final previousState = _connectionState;
    _connectionState = newState;
    _errorMessage = error;
    
    // Handle state transitions
    switch (newState) {
      case ConnectionState.connected:
        _onConnectionEstablished();
        break;
        
      case ConnectionState.disconnected:
        _onConnectionLost(previousState);
        break;
        
      case ConnectionState.error:
        _onConnectionError();
        break;
        
      case ConnectionState.scanning:
      case ConnectionState.connecting:
        _onConnectionAttempt();
        break;
    }
    
    notifyListeners();
  }

  /// Handle successful connection
  void _onConnectionEstablished() {
    _connectionTime = DateTime.now();
    _connectedDeviceName = _bleService.connectedDevice?.platformName ?? 'ESP32';
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    
    _addToLog('Connected to $_connectedDeviceName');
    _startConnectionTimer();
  }

  /// Handle connection loss
  void _onConnectionLost(ConnectionState previousState) {
    _connectedDeviceName = null;
    _connectionTime = null;
    _connectionDuration = Duration.zero;
    _connectionTimer?.cancel();
    
    _addToLog('Connection lost');
    
    // Start auto-reconnect if enabled and connection was established
    if (_autoReconnectEnabled && previousState == ConnectionState.connected) {
      _startAutoReconnect();
    }
  }

  /// Handle connection error
  void _onConnectionError() {
    _addToLog('Connection error: $_errorMessage');
    
    // Retry if auto-reconnect is enabled
    if (_autoReconnectEnabled && _reconnectAttempts < ESP32Constants.maxReconnectAttempts) {
      _startAutoReconnect();
    }
  }

  /// Handle connection attempt
  void _onConnectionAttempt() {
    if (_connectionState == ConnectionState.scanning) {
      _addToLog('Scanning for ESP32 device...');
    } else if (_connectionState == ConnectionState.connecting) {
      _addToLog('Connecting to device...');
    }
  }

  /// Connect to ESP32 device
  Future<bool> connect() async {
    if (isConnecting) return false;
    
    _addToLog('Initiating connection...');
    _reconnectAttempts = 0;
    
    final success = await _bleService.connectToDevice();
    
    if (!success && _autoReconnectEnabled) {
      _startAutoReconnect();
    }
    
    return success;
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    _autoReconnectEnabled = false; // Disable auto-reconnect for manual disconnect
    _reconnectTimer?.cancel();
    
    await _bleService.disconnect();
    _addToLog('Manually disconnected');
  }

  /// Enable/disable auto-reconnect
  void setAutoReconnect(bool enabled) {
    _autoReconnectEnabled = enabled;
    
    if (!enabled) {
      _reconnectTimer?.cancel();
      _reconnectAttempts = 0;
    }
    
    _addToLog('Auto-reconnect ${enabled ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  /// Start auto-reconnect process
  void _startAutoReconnect() {
    if (!_autoReconnectEnabled || _reconnectAttempts >= ESP32Constants.maxReconnectAttempts) {
      _addToLog('Max reconnect attempts reached');
      return;
    }
    
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2); // Exponential backoff
    
    _addToLog('Auto-reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (!isConnected && _autoReconnectEnabled) {
        _addToLog('Attempting auto-reconnect...');
        await _bleService.connectToDevice();
      }
    });
  }

  /// Start connection duration timer
  void _startConnectionTimer() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_connectionTime != null) {
        _connectionDuration = DateTime.now().difference(_connectionTime!);
        notifyListeners();
      }
    });
  }

  /// Start connection monitoring
  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isConnected) {
        _addToLog('Connection healthy - ${_formatDuration(_connectionDuration)}');
      }
    });
  }

  /// Add message to connection log
  void _addToLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    
    _connectionLog.add(logEntry);
    if (_connectionLog.length > 100) {
      _connectionLog.removeAt(0);
    }
    
    debugPrint('ConnectionController: $logEntry');
    notifyListeners();
  }

  /// Clear connection log
  void clearLog() {
    _connectionLog.clear();
    notifyListeners();
  }

  /// Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'isConnected': isConnected,
      'connectionDuration': _formatDuration(_connectionDuration),
      'reconnectAttempts': _reconnectAttempts,
      'autoReconnectEnabled': _autoReconnectEnabled,
      'deviceName': _connectedDeviceName,
      'connectionTime': _connectionTime?.toIso8601String(),
      'logEntries': _connectionLog.length,
    };
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Get formatted connection duration
  String get formattedConnectionDuration {
    return _formatDuration(_connectionDuration);
  }

  /// Reset reconnection attempts
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
    notifyListeners();
  }

  /// Force reconnection attempt
  Future<bool> forceReconnect() async {
    if (isConnected) {
      await disconnect();
      await Future.delayed(const Duration(seconds: 1));
    }
    
    _reconnectAttempts = 0;
    return await connect();
  }

  /// Test connection health
  Future<bool> testConnection() async {
    if (!isConnected) return false;
    
    try {
      // Try to read motor status as a connection test
      final device = _bleService.connectedDevice;
      if (device == null) return false;
      
      final state = await device.connectionState.first;
      final isHealthy = state.name == 'connected';
      
      _addToLog('Connection test: ${isHealthy ? 'PASS' : 'FAIL'}');
      return isHealthy;
    } catch (e) {
      _addToLog('Connection test failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _connectionTimer?.cancel();
    _monitoringTimer?.cancel();
    _bleService.removeListener(_onBleStateChanged);
    super.dispose();
  }
}
