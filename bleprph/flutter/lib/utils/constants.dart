/// ESP32 Stepper Motor Controller - Constants and Configuration
class ESP32Constants {
  // Device identification
  static const String deviceName = 'ESP32_StepperMotor';
  static const String devicePrefix = 'nimble-bleprph';
  
  // BLE Service UUIDs
  static const String ledServiceUuid = '12345678-90ab-cdef-1234-567890abcdef';
  static const String motorServiceUuid = '87654321-abcd-ef90-1234-567890abcdef';
  
  // LED Characteristic UUIDs
  static const String led1CharUuid = '12345678-90ab-cdef-1234-567890abcd01';
  static const String led2CharUuid = '12345678-90ab-cdef-1234-567890abcd02';
  static const String led3CharUuid = '12345678-90ab-cdef-1234-567890abcd03';
  static const String led4CharUuid = '12345678-90ab-cdef-1234-567890abcd04';
  
  // Motor Characteristic UUIDs
  static const String motorPositionUuid = '87654321-abcd-ef90-1234-567890abcd01';
  static const String motorCommandUuid = '87654321-abcd-ef90-1234-567890abcd02';
  static const String motorStatusUuid = '87654321-abcd-ef90-1234-567890abcd03';
  static const String motorSpeedUuid = '87654321-abcd-ef90-1234-567890abcd04';
  
  // Motor specifications
  static const int stepsPerRevolution = 200;
  static const double threadPitchMm = 2.0;
  static const double stepsPerMm = stepsPerRevolution / threadPitchMm; // ~100 steps/mm
  static const int strokeLengthMm = 90;
  static const int maxSteps = 200;
  static const int minSteps = 0;
  
  // Speed limits
  static const int minSpeedMs = 1;
  static const int maxSpeedMs = 1000;
  static const int defaultSpeedMs = 100;
  
  // Connection settings
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration scanTimeout = Duration(seconds: 15);
  static const int maxReconnectAttempts = 3;
  
  // UI Configuration
  static const Duration uiUpdateInterval = Duration(milliseconds: 100);
  static const Duration commandFeedbackDuration = Duration(milliseconds: 200);
}

/// Motor position presets for quick access
class MotorPresets {
  static const Map<String, int> positions = {
    'Home': 0,
    'Quarter': 50,
    'Half': 100,
    'Three-Quarter': 150,
    'End': 200,
  };
  
  static const Map<String, int> speeds = {
    'Very Slow': 500,
    'Slow': 200,
    'Normal': 100,
    'Fast': 50,
    'Very Fast': 10,
  };
}
