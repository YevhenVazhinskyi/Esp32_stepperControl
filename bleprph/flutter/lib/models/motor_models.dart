import 'dart:typed_data';

/// Motor command enumeration matching ESP32 implementation
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
  
  /// Create command packet: [command:1][parameter:2]
  Uint8List createPacket(int parameter) {
    final packet = Uint8List(3);
    packet[0] = value;
    packet[1] = parameter & 0xFF;        // Low byte
    packet[2] = (parameter >> 8) & 0xFF; // High byte
    return packet;
  }
}

/// Motor status enumeration
enum MotorStatus {
  idle(0),
  moving(1),
  error(2),
  disabled(3);

  const MotorStatus(this.value);
  final int value;
  
  static MotorStatus fromValue(int value) {
    return MotorStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MotorStatus.idle,
    );
  }
  
  String get displayName {
    switch (this) {
      case MotorStatus.idle:
        return 'Idle';
      case MotorStatus.moving:
        return 'Moving';
      case MotorStatus.error:
        return 'Error';
      case MotorStatus.disabled:
        return 'Disabled';
    }
  }
}

/// Complete motor state information
class MotorState {
  final int position;           // Current position in steps
  final int targetPosition;     // Target position in steps
  final MotorStatus status;     // Current motor status
  final bool isFault;          // Hardware fault status
  final int speedMs;           // Current speed in milliseconds
  final bool isEnabled;        // Motor driver enabled
  final DateTime timestamp;    // Last update time
  
  const MotorState({
    required this.position,
    required this.targetPosition,
    required this.status,
    required this.isFault,
    required this.speedMs,
    required this.isEnabled,
    required this.timestamp,
  });
  
  /// Create MotorState from status packet [status:1][position:2][fault:1]
  factory MotorState.fromStatusPacket(Uint8List data, int speedMs) {
    if (data.length < 4) {
      throw ArgumentError('Status packet must be at least 4 bytes');
    }
    
    final status = MotorStatus.fromValue(data[0]);
    final position = data[1] | (data[2] << 8);
    final isFault = data[3] != 0;
    
    return MotorState(
      position: position,
      targetPosition: position, // Will be updated from position characteristic
      status: status,
      isFault: isFault,
      speedMs: speedMs,
      isEnabled: status != MotorStatus.disabled,
      timestamp: DateTime.now(),
    );
  }
  
  /// Convert position to millimeters
  double get positionMm => position / 2.22; // ~2.22 steps per mm
  
  /// Convert target position to millimeters
  double get targetPositionMm => targetPosition / 2.22;
  
  /// Get progress percentage (0-100)
  double get progressPercent => (position / 200.0) * 100.0;
  
  /// Check if motor is currently moving
  bool get isMoving => status == MotorStatus.moving;
  
  /// Copy with updated values
  MotorState copyWith({
    int? position,
    int? targetPosition,
    MotorStatus? status,
    bool? isFault,
    int? speedMs,
    bool? isEnabled,
    DateTime? timestamp,
  }) {
    return MotorState(
      position: position ?? this.position,
      targetPosition: targetPosition ?? this.targetPosition,
      status: status ?? this.status,
      isFault: isFault ?? this.isFault,
      speedMs: speedMs ?? this.speedMs,
      isEnabled: isEnabled ?? this.isEnabled,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  @override
  String toString() {
    return 'MotorState(pos: $position/$targetPosition, status: $status, '
           'fault: $isFault, speed: ${speedMs}ms, enabled: $isEnabled)';
  }
}

/// LED state management
class LedState {
  final bool led1;
  final bool led2;
  final bool led3;
  final bool led4;
  final DateTime timestamp;
  
  const LedState({
    required this.led1,
    required this.led2,
    required this.led3,
    required this.led4,
    required this.timestamp,
  });
  
  /// Create initial state with all LEDs off
  factory LedState.initial() {
    return LedState(
      led1: false,
      led2: false,
      led3: false,
      led4: false,
      timestamp: DateTime.now(),
    );
  }
  
  /// Get LED state by index (0-3)
  bool getLed(int index) {
    switch (index) {
      case 0: return led1;
      case 1: return led2;
      case 2: return led3;
      case 3: return led4;
      default: throw ArgumentError('LED index must be 0-3');
    }
  }
  
  /// Create new state with LED toggled
  LedState toggleLed(int index) {
    switch (index) {
      case 0: return copyWith(led1: !led1);
      case 1: return copyWith(led2: !led2);
      case 2: return copyWith(led3: !led3);
      case 3: return copyWith(led4: !led4);
      default: throw ArgumentError('LED index must be 0-3');
    }
  }
  
  /// Copy with updated values
  LedState copyWith({
    bool? led1,
    bool? led2,
    bool? led3,
    bool? led4,
    DateTime? timestamp,
  }) {
    return LedState(
      led1: led1 ?? this.led1,
      led2: led2 ?? this.led2,
      led3: led3 ?? this.led3,
      led4: led4 ?? this.led4,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  @override
  String toString() {
    return 'LedState(1:$led1, 2:$led2, 3:$led3, 4:$led4)';
  }
}

/// Connection state management
enum ConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error;
  
  String get displayName {
    switch (this) {
      case ConnectionState.disconnected:
        return 'Disconnected';
      case ConnectionState.scanning:
        return 'Scanning...';
      case ConnectionState.connecting:
        return 'Connecting...';
      case ConnectionState.connected:
        return 'Connected';
      case ConnectionState.error:
        return 'Connection Error';
    }
  }
  
  bool get isConnected => this == ConnectionState.connected;
  bool get canConnect => this == ConnectionState.disconnected;
  bool get isConnecting => this == ConnectionState.connecting || this == ConnectionState.scanning;
}
