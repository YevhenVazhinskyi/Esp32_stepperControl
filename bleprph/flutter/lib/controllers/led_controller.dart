import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/motor_models.dart';
import '../services/ble_service.dart';

/// LED control with patterns and effects
class LedController extends ChangeNotifier {
  final BleService _bleService = BleService();
  
  // Current LED state
  LedState _ledState = LedState.initial();
  
  // Pattern control
  bool _patternRunning = false;
  Timer? _patternTimer;
  String? _currentPattern;
  
  // Individual LED control
  final List<bool> _ledTargetStates = [false, false, false, false];
  
  // Animation control
  Timer? _animationTimer;
  int _animationStep = 0;

  // Stream subscription
  StreamSubscription? _stateSubscription;

  // Getters
  LedState get ledState => _ledState;
  bool get patternRunning => _patternRunning;
  String? get currentPattern => _currentPattern;
  List<bool> get ledTargetStates => List.unmodifiable(_ledTargetStates);

  LedController() {
    _initController();
  }

  /// Initialize LED controller
  Future<void> _initController() async {
    // Listen to LED state updates from BLE service
    _stateSubscription = _bleService.ledStateStream.listen((state) {
      _updateLedState(state);
    });
  }

  /// Update LED state from BLE service
  void _updateLedState(LedState newState) {
    _ledState = newState;
    
    // Update target states to match actual states
    _ledTargetStates[0] = newState.led1;
    _ledTargetStates[1] = newState.led2;
    _ledTargetStates[2] = newState.led3;
    _ledTargetStates[3] = newState.led4;
    
    notifyListeners();
  }

  /// Set individual LED state
  Future<bool> setLed(int ledIndex, bool state) async {
    if (ledIndex < 0 || ledIndex > 3) return false;
    
    _ledTargetStates[ledIndex] = state;
    notifyListeners();
    
    return await _bleService.setLedState(ledIndex, state);
  }

  /// Toggle individual LED
  Future<bool> toggleLed(int ledIndex) async {
    if (ledIndex < 0 || ledIndex > 3) return false;
    
    final currentState = _ledState.getLed(ledIndex);
    return await setLed(ledIndex, !currentState);
  }

  /// Set all LEDs to the same state
  Future<bool> setAllLeds(bool state) async {
    final futures = <Future<bool>>[];
    
    for (int i = 0; i < 4; i++) {
      futures.add(setLed(i, state));
    }
    
    final results = await Future.wait(futures);
    return results.every((result) => result);
  }

  /// Turn all LEDs on
  Future<bool> turnAllOn() async {
    return await setAllLeds(true);
  }

  /// Turn all LEDs off
  Future<bool> turnAllOff() async {
    return await setAllLeds(false);
  }

  /// Start LED pattern
  Future<void> startPattern(String patternName) async {
    await stopPattern();
    
    _currentPattern = patternName;
    _patternRunning = true;
    _animationStep = 0;
    notifyListeners();
    
    switch (patternName) {
      case 'blink_all':
        _startBlinkAllPattern();
        break;
      case 'chase':
        _startChasePattern();
        break;
      case 'wave':
        _startWavePattern();
        break;
      case 'heartbeat':
        _startHeartbeatPattern();
        break;
      case 'binary_counter':
        _startBinaryCounterPattern();
        break;
      case 'breathing':
        _startBreathingPattern();
        break;
      default:
        await stopPattern();
    }
  }

  /// Stop current pattern
  Future<void> stopPattern() async {
    _patternTimer?.cancel();
    _animationTimer?.cancel();
    _patternRunning = false;
    _currentPattern = null;
    _animationStep = 0;
    notifyListeners();
    
    // Turn off all LEDs when stopping pattern
    await turnAllOff();
  }

  /// Blink all LEDs simultaneously
  void _startBlinkAllPattern() {
    _patternTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      final state = _animationStep % 2 == 0;
      await setAllLeds(state);
      _animationStep++;
    });
  }

  /// Chase pattern (LEDs light up in sequence)
  void _startChasePattern() {
    _patternTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      await setAllLeds(false);
      await Future.delayed(const Duration(milliseconds: 50));
      await setLed(_animationStep % 4, true);
      _animationStep++;
    });
  }

  /// Wave pattern (smooth transition)
  void _startWavePattern() {
    _patternTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      await setAllLeds(false);
      
      // Light up LEDs in wave pattern
      final positions = [
        [true, false, false, false],
        [true, true, false, false],
        [false, true, true, false],
        [false, false, true, true],
        [false, false, false, true],
        [false, false, true, true],
        [false, true, true, false],
        [true, true, false, false],
      ];
      
      final pattern = positions[_animationStep % positions.length];
      for (int i = 0; i < 4; i++) {
        await setLed(i, pattern[i]);
      }
      _animationStep++;
    });
  }

  /// Heartbeat pattern (double pulse)
  void _startHeartbeatPattern() {
    _patternTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      final sequence = [
        true, false, true, false, false, false, false, false, false, false
      ];
      
      final state = sequence[_animationStep % sequence.length];
      await setAllLeds(state);
      _animationStep++;
    });
  }

  /// Binary counter pattern
  void _startBinaryCounterPattern() {
    _patternTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      final count = _animationStep % 16; // 4-bit counter (0-15)
      
      for (int i = 0; i < 4; i++) {
        final bitValue = (count >> i) & 1;
        await setLed(i, bitValue == 1);
      }
      _animationStep++;
    });
  }

  /// Breathing pattern (smooth fade effect simulation)
  void _startBreathingPattern() {
    _patternTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      final breatheSequence = [
        [false, false, false, false], // Off
        [true, false, false, false],  // Fade in
        [true, true, false, false],
        [true, true, true, false],
        [true, true, true, true],     // Full brightness
        [true, true, true, false],    // Fade out
        [true, true, false, false],
        [true, false, false, false],
      ];
      
      final pattern = breatheSequence[_animationStep % breatheSequence.length];
      for (int i = 0; i < 4; i++) {
        await setLed(i, pattern[i]);
      }
      _animationStep++;
    });
  }

  /// Flash specific pattern for notifications
  Future<void> flashNotification(String type) async {
    switch (type) {
      case 'success':
        await _flashSuccess();
        break;
      case 'error':
        await _flashError();
        break;
      case 'warning':
        await _flashWarning();
        break;
      case 'info':
        await _flashInfo();
        break;
    }
  }

  /// Flash success pattern (green simulation - LED1 and LED3)
  Future<void> _flashSuccess() async {
    for (int i = 0; i < 3; i++) {
      await setLed(0, true);  // LED1
      await setLed(2, true);  // LED3
      await Future.delayed(const Duration(milliseconds: 150));
      await setLed(0, false);
      await setLed(2, false);
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  /// Flash error pattern (red simulation - LED2 and LED4)
  Future<void> _flashError() async {
    for (int i = 0; i < 5; i++) {
      await setLed(1, true);  // LED2
      await setLed(3, true);  // LED4
      await Future.delayed(const Duration(milliseconds: 100));
      await setLed(1, false);
      await setLed(3, false);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Flash warning pattern (yellow simulation - LED1 and LED2)
  Future<void> _flashWarning() async {
    for (int i = 0; i < 4; i++) {
      await setLed(0, true);  // LED1
      await setLed(1, true);  // LED2
      await Future.delayed(const Duration(milliseconds: 200));
      await setLed(0, false);
      await setLed(1, false);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Flash info pattern (blue simulation - LED3 and LED4)
  Future<void> _flashInfo() async {
    for (int i = 0; i < 2; i++) {
      await setLed(2, true);  // LED3
      await setLed(3, true);  // LED4
      await Future.delayed(const Duration(milliseconds: 300));
      await setLed(2, false);
      await setLed(3, false);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// Get available patterns
  List<String> getAvailablePatterns() {
    return [
      'blink_all',
      'chase',
      'wave',
      'heartbeat',
      'binary_counter',
      'breathing',
    ];
  }

  /// Get pattern display names
  Map<String, String> getPatternDisplayNames() {
    return {
      'blink_all': 'Blink All',
      'chase': 'Chase',
      'wave': 'Wave',
      'heartbeat': 'Heartbeat',
      'binary_counter': 'Binary Counter',
      'breathing': 'Breathing',
    };
  }

  /// Test all LEDs sequentially
  Future<void> testAllLeds() async {
    await stopPattern();
    
    // Test each LED individually
    for (int i = 0; i < 4; i++) {
      await setAllLeds(false);
      await Future.delayed(const Duration(milliseconds: 200));
      await setLed(i, true);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Flash all together
    await setAllLeds(false);
    await Future.delayed(const Duration(milliseconds: 200));
    await setAllLeds(true);
    await Future.delayed(const Duration(milliseconds: 500));
    await setAllLeds(false);
  }

  /// Get LED status summary
  Map<String, dynamic> getLedStatus() {
    return {
      'led1': _ledState.led1,
      'led2': _ledState.led2,
      'led3': _ledState.led3,
      'led4': _ledState.led4,
      'patternRunning': _patternRunning,
      'currentPattern': _currentPattern,
      'animationStep': _animationStep,
      'lastUpdate': _ledState.timestamp.toIso8601String(),
    };
  }

  @override
  void dispose() {
    _patternTimer?.cancel();
    _animationTimer?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }
}
