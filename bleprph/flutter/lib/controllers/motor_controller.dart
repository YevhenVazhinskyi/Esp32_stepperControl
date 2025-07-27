import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/motor_models.dart';
import '../services/ble_service.dart';
import '../utils/constants.dart';

/// Motor control state management with advanced features
class MotorController extends ChangeNotifier {
  final BleService _bleService = BleService();
  
  // Current state
  MotorState _motorState = MotorState(
    position: 0,
    targetPosition: 0,
    status: MotorStatus.idle,
    isFault: false,
    speedMs: ESP32Constants.defaultSpeedMs,
    isEnabled: false,
    timestamp: DateTime.now(),
  );
  
  // UI state
  bool _isJogging = false;
  int _jogStepSize = 5;
  List<int> _positionHistory = [];
  Map<String, int> _customPresets = {};
  
  // Auto-update timer  
  Timer? _updateTimer;
  StreamSubscription? _stateSubscription;

  // Getters
  MotorState get motorState => _motorState;
  bool get isJogging => _isJogging;
  int get jogStepSize => _jogStepSize;
  List<int> get positionHistory => List.unmodifiable(_positionHistory);
  Map<String, int> get customPresets => Map.unmodifiable(_customPresets);
  
  // Computed properties
  bool get canMoveForward => _motorState.position < ESP32Constants.maxSteps;
  bool get canMoveBackward => _motorState.position > ESP32Constants.minSteps;
  bool get isAtHome => _motorState.position == 0;
  bool get isAtEnd => _motorState.position >= ESP32Constants.maxSteps;
  double get progressPercent => (_motorState.position / ESP32Constants.maxSteps) * 100;

  MotorController() {
    _initController();
  }

  /// Initialize controller
  Future<void> _initController() async {
    // Listen to BLE motor state updates
    _stateSubscription = _bleService.motorStateStream.listen((state) {
      _updateMotorState(state);
    });
    
    // Load saved presets
    await _loadPresets();
    
    // Start periodic updates
    _startUpdateTimer();
  }

  /// Update motor state and notify listeners
  void _updateMotorState(MotorState newState) {
    final positionChanged = newState.position != _motorState.position;
    _motorState = newState;
    
    // Add to position history if position changed
    if (positionChanged) {
      _addToHistory(newState.position);
    }
    
    notifyListeners();
  }

  /// Add position to history
  void _addToHistory(int position) {
    _positionHistory.add(position);
    if (_positionHistory.length > 50) {
      _positionHistory.removeAt(0);
    }
  }

  /// Start update timer for UI refresh
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(ESP32Constants.uiUpdateInterval, (timer) {
      notifyListeners(); // Refresh UI timestamps, etc.
    });
  }

  /// Move to absolute position
  Future<bool> moveToPosition(int position) async {
    final clampedPosition = position.clamp(ESP32Constants.minSteps, ESP32Constants.maxSteps);
    return await _bleService.sendMotorCommand(MotorCommand.moveAbsolute, clampedPosition);
  }

  /// Move relative steps
  Future<bool> moveRelative(int steps) async {
    final targetPosition = (_motorState.position + steps)
        .clamp(ESP32Constants.minSteps, ESP32Constants.maxSteps);
    final actualSteps = targetPosition - _motorState.position;
    return await _bleService.sendMotorCommand(MotorCommand.moveRelative, actualSteps);
  }

  /// Jog motor forward
  Future<bool> jogForward() async {
    if (!canMoveForward || _isJogging) return false;
    
    _isJogging = true;
    notifyListeners();
    
    final success = await moveRelative(_jogStepSize);
    
    // Add small delay to prevent rapid commands
    await Future.delayed(const Duration(milliseconds: 100));
    _isJogging = false;
    notifyListeners();
    
    return success;
  }

  /// Jog motor backward
  Future<bool> jogBackward() async {
    if (!canMoveBackward || _isJogging) return false;
    
    _isJogging = true;
    notifyListeners();
    
    final success = await moveRelative(-_jogStepSize);
    
    await Future.delayed(const Duration(milliseconds: 100));
    _isJogging = false;
    notifyListeners();
    
    return success;
  }

  /// Set jog step size
  void setJogStepSize(int steps) {
    _jogStepSize = steps.clamp(1, 50);
    notifyListeners();
  }

  /// Home motor to position 0
  Future<bool> homeMotor() async {
    return await _bleService.sendMotorCommand(MotorCommand.home);
  }

  /// Stop motor immediately
  Future<bool> stopMotor() async {
    return await _bleService.sendMotorCommand(MotorCommand.stop);
  }

  /// Enable motor driver
  Future<bool> enableMotor() async {
    return await _bleService.sendMotorCommand(MotorCommand.enable);
  }

  /// Disable motor driver
  Future<bool> disableMotor() async {
    return await _bleService.sendMotorCommand(MotorCommand.disable);
  }

  /// Set motor speed
  Future<bool> setSpeed(int speedMs) async {
    return await _bleService.setMotorSpeed(speedMs);
  }

  /// Move to preset position
  Future<bool> moveToPreset(String presetName) async {
    int? position;
    
    // Check built-in presets first
    if (MotorPresets.positions.containsKey(presetName)) {
      position = MotorPresets.positions[presetName];
    } else if (_customPresets.containsKey(presetName)) {
      position = _customPresets[presetName];
    }
    
    if (position != null) {
      return await moveToPosition(position);
    }
    return false;
  }

  /// Save current position as custom preset
  Future<bool> saveCurrentPositionAsPreset(String name) async {
    if (name.isEmpty) return false;
    
    _customPresets[name] = _motorState.position;
    await _savePresets();
    notifyListeners();
    return true;
  }

  /// Delete custom preset
  Future<bool> deletePreset(String name) async {
    if (_customPresets.containsKey(name)) {
      _customPresets.remove(name);
      await _savePresets();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Get all available presets (built-in + custom)
  Map<String, int> getAllPresets() {
    final allPresets = <String, int>{};
    allPresets.addAll(MotorPresets.positions);
    allPresets.addAll(_customPresets);
    return allPresets;
  }

  /// Emergency stop - immediate stop command
  Future<bool> emergencyStop() async {
    _isJogging = false;
    notifyListeners();
    return await stopMotor();
  }

  /// Calculate estimated movement time
  Duration getEstimatedMoveTime(int targetPosition) {
    final steps = (targetPosition - _motorState.position).abs();
    final totalTimeMs = steps * _motorState.speedMs;
    return Duration(milliseconds: totalTimeMs);
  }

  /// Check if position is safe (within limits)
  bool isPositionSafe(int position) {
    return position >= ESP32Constants.minSteps && position <= ESP32Constants.maxSteps;
  }

  /// Get position in millimeters
  double getPositionMm(int steps) {
    return steps / ESP32Constants.stepsPerMm;
  }

  /// Convert millimeters to steps
  int getStepsFromMm(double mm) {
    return (mm * ESP32Constants.stepsPerMm).round();
  }

  /// Load custom presets from storage
  Future<void> _loadPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetKeys = prefs.getKeys().where((key) => key.startsWith('preset_'));
      
      for (final key in presetKeys) {
        final name = key.substring(7); // Remove 'preset_' prefix
        final position = prefs.getInt(key);
        if (position != null) {
          _customPresets[name] = position;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load presets: $e');
    }
  }

  /// Save custom presets to storage
  Future<void> _savePresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear existing presets
      final existingKeys = prefs.getKeys().where((key) => key.startsWith('preset_'));
      for (final key in existingKeys) {
        await prefs.remove(key);
      }
      
      // Save current presets
      for (final entry in _customPresets.entries) {
        await prefs.setInt('preset_${entry.key}', entry.value);
      }
    } catch (e) {
      debugPrint('Failed to save presets: $e');
    }
  }

  /// Clear position history
  void clearHistory() {
    _positionHistory.clear();
    notifyListeners();
  }

  /// Get movement statistics
  Map<String, dynamic> getMovementStats() {
    if (_positionHistory.isEmpty) {
      return {
        'totalMoves': 0,
        'averagePosition': 0,
        'maxPosition': 0,
        'minPosition': 0,
        'totalDistance': 0,
      };
    }

    final totalMoves = _positionHistory.length;
    final averagePosition = _positionHistory.reduce((a, b) => a + b) / totalMoves;
    final maxPosition = _positionHistory.reduce((a, b) => a > b ? a : b);
    final minPosition = _positionHistory.reduce((a, b) => a < b ? a : b);
    
    // Calculate total distance traveled
    int totalDistance = 0;
    for (int i = 1; i < _positionHistory.length; i++) {
      totalDistance += (_positionHistory[i] - _positionHistory[i - 1]).abs();
    }

    return {
      'totalMoves': totalMoves,
      'averagePosition': averagePosition.round(),
      'maxPosition': maxPosition,
      'minPosition': minPosition,
      'totalDistance': totalDistance,
    };
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }
}
