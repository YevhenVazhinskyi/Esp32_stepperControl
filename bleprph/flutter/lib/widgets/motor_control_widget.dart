import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/motor_controller.dart';
import '../controllers/connection_controller.dart';
import '../models/motor_models.dart';
import '../utils/constants.dart';

/// Comprehensive motor control widget
class MotorControlWidget extends StatefulWidget {
  const MotorControlWidget({super.key});

  @override
  State<MotorControlWidget> createState() => _MotorControlWidgetState();
}

class _MotorControlWidgetState extends State<MotorControlWidget> {
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _speedController = TextEditingController();
  final TextEditingController _presetNameController = TextEditingController();
  
  int _targetPosition = 0;
  int _targetSpeed = ESP32Constants.defaultSpeedMs;
  bool _showPresetDialog = false;

  @override
  void initState() {
    super.initState();
    _speedController.text = _targetSpeed.toString();
  }

  @override
  void dispose() {
    _positionController.dispose();
    _speedController.dispose();
    _presetNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MotorController, ConnectionController>(
      builder: (context, motorController, connectionController, child) {
        final isConnected = connectionController.isConnected;
        final motorState = motorController.motorState;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Motor Status Card
            _buildStatusCard(context, motorState, isConnected),
            
            const SizedBox(height: 16),
            
            // Position Control Card
            _buildPositionControlCard(context, motorController, isConnected),
            
            const SizedBox(height: 16),
            
            // Speed Control Card
            _buildSpeedControlCard(context, motorController, isConnected),
            
            const SizedBox(height: 16),
            
            // Preset Positions Card
            _buildPresetsCard(context, motorController, isConnected),
            
            const SizedBox(height: 16),
            
            // Movement Controls Card
            _buildMovementControlsCard(context, motorController, isConnected),
            
            const SizedBox(height: 16),
            
            // Advanced Controls Card
            _buildAdvancedControlsCard(context, motorController, isConnected),
          ],
        );
      },
    );
  }

  /// Build motor status card
  Widget _buildStatusCard(BuildContext context, MotorState motorState, bool isConnected) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Motor Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(motorState.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    motorState.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status information grid
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    context,
                    'Position',
                    '${motorState.position} steps',
                    '${motorState.positionMm.toStringAsFixed(1)} mm',
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    context,
                    'Speed',
                    '${motorState.speedMs} ms',
                    'per step',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    context,
                    'Progress',
                    '${motorState.progressPercent.toStringAsFixed(1)}%',
                    '${motorState.position}/${ESP32Constants.maxSteps}',
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    context,
                    'Status',
                    motorState.isFault ? 'FAULT' : 'OK',
                    motorState.isEnabled ? 'Enabled' : 'Disabled',
                    textColor: motorState.isFault ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Progress bar
            LinearProgressIndicator(
              value: motorState.position / ESP32Constants.maxSteps,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                motorState.isMoving ? Colors.blue : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build position control card
  Widget _buildPositionControlCard(BuildContext context, MotorController motorController, bool isConnected) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Position Control',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Position slider
            Text(
              'Target Position: $_targetPosition steps (${(_targetPosition / ESP32Constants.stepsPerMm).toStringAsFixed(1)} mm)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 8),
            
            Slider(
              value: _targetPosition.toDouble(),
              min: ESP32Constants.minSteps.toDouble(),
              max: ESP32Constants.maxSteps.toDouble(),
              divisions: ESP32Constants.maxSteps,
              label: '$_targetPosition',
              onChanged: isConnected ? (value) {
                setState(() {
                  _targetPosition = value.round();
                });
              } : null,
            ),
            
            const SizedBox(height: 16),
            
            // Manual position input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _positionController,
                    decoration: const InputDecoration(
                      labelText: 'Position (steps)',
                      border: OutlineInputBorder(),
                      suffixText: 'steps',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: isConnected,
                    onChanged: (value) {
                      final pos = int.tryParse(value);
                      if (pos != null && pos >= ESP32Constants.minSteps && pos <= ESP32Constants.maxSteps) {
                        setState(() {
                          _targetPosition = pos;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isConnected ? () {
                    motorController.moveToPosition(_targetPosition);
                  } : null,
                  child: const Text('Move'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Jog controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'Jog Size: ${motorController.jogStepSize} steps',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: isConnected ? () {
                            motorController.setJogStepSize(motorController.jogStepSize - 1);
                          } : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('${motorController.jogStepSize}'),
                        IconButton(
                          onPressed: isConnected ? () {
                            motorController.setJogStepSize(motorController.jogStepSize + 1);
                          } : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
                
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: isConnected && motorController.canMoveBackward && !motorController.isJogging
                          ? motorController.jogBackward : null,
                      icon: const Icon(Icons.keyboard_arrow_left),
                      label: const Text('Jog -'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: isConnected && motorController.canMoveForward && !motorController.isJogging
                          ? motorController.jogForward : null,
                      icon: const Icon(Icons.keyboard_arrow_right),
                      label: const Text('Jog +'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build speed control card
  Widget _buildSpeedControlCard(BuildContext context, MotorController motorController, bool isConnected) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Speed Control',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Speed: $_targetSpeed ms per step',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 8),
            
            Slider(
              value: _targetSpeed.toDouble(),
              min: ESP32Constants.minSpeedMs.toDouble(),
              max: ESP32Constants.maxSpeedMs.toDouble(),
              divisions: 100,
              label: '${_targetSpeed}ms',
              onChanged: isConnected ? (value) {
                setState(() {
                  _targetSpeed = value.round();
                });
              } : null,
            ),
            
            const SizedBox(height: 16),
            
            // Speed presets
            Wrap(
              spacing: 8,
              children: MotorPresets.speeds.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.key),
                  selected: _targetSpeed == entry.value,
                  onSelected: isConnected ? (selected) {
                    if (selected) {
                      setState(() {
                        _targetSpeed = entry.value;
                      });
                      motorController.setSpeed(entry.value);
                    }
                  } : null,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _speedController,
                    decoration: const InputDecoration(
                      labelText: 'Speed (ms)',
                      border: OutlineInputBorder(),
                      suffixText: 'ms',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: isConnected,
                    onChanged: (value) {
                      final speed = int.tryParse(value);
                      if (speed != null && speed >= ESP32Constants.minSpeedMs && speed <= ESP32Constants.maxSpeedMs) {
                        setState(() {
                          _targetSpeed = speed;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isConnected ? () {
                    motorController.setSpeed(_targetSpeed);
                  } : null,
                  child: const Text('Set'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build presets card
  Widget _buildPresetsCard(BuildContext context, MotorController motorController, bool isConnected) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Preset Positions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: isConnected ? () {
                    _showSavePresetDialog(context, motorController);
                  } : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Save'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Built-in presets
            Text(
              'Built-in Presets',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MotorPresets.positions.entries.map((entry) {
                return ActionChip(
                  label: Text('${entry.key} (${entry.value})'),
                  onPressed: isConnected ? () {
                    motorController.moveToPreset(entry.key);
                  } : null,
                );
              }).toList(),
            ),
            
            // Custom presets
            if (motorController.customPresets.isNotEmpty) ...[
              const SizedBox(height: 16),
              
              Text(
                'Custom Presets',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: motorController.customPresets.entries.map((entry) {
                  return ActionChip(
                    label: Text('${entry.key} (${entry.value})'),
                    onPressed: isConnected ? () {
                      motorController.moveToPreset(entry.key);
                    } : null,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      motorController.deletePreset(entry.key);
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build movement controls card
  Widget _buildMovementControlsCard(BuildContext context, MotorController motorController, bool isConnected) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.control_camera, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Movement Controls',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? motorController.homeMotor : null,
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? motorController.stopMotor : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? motorController.enableMotor : null,
                    icon: const Icon(Icons.power),
                    label: const Text('Enable'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? motorController.disableMotor : null,
                    icon: const Icon(Icons.power_off),
                    label: const Text('Disable'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build advanced controls card
  Widget _buildAdvancedControlsCard(BuildContext context, MotorController motorController, bool isConnected) {
    final stats = motorController.getMovementStats();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Advanced Controls',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ExpansionTile(
              title: const Text('Movement Statistics'),
              children: [
                _buildStatsRow(context, 'Total Moves', '${stats['totalMoves']}'),
                _buildStatsRow(context, 'Average Position', '${stats['averagePosition']} steps'),
                _buildStatsRow(context, 'Max Position', '${stats['maxPosition']} steps'),
                _buildStatsRow(context, 'Min Position', '${stats['minPosition']} steps'),
                _buildStatsRow(context, 'Total Distance', '${stats['totalDistance']} steps'),
                
                const SizedBox(height: 8),
                
                TextButton(
                  onPressed: motorController.clearHistory,
                  child: const Text('Clear History'),
                ),
              ],
            ),
            
            ExpansionTile(
              title: const Text('Emergency Controls'),
              children: [
                ListTile(
                  leading: const Icon(Icons.emergency, color: Colors.red),
                  title: const Text('Emergency Stop'),
                  subtitle: const Text('Immediately stop all motor movement'),
                  trailing: ElevatedButton(
                    onPressed: isConnected ? motorController.emergencyStop : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('STOP'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show save preset dialog
  void _showSavePresetDialog(BuildContext context, MotorController motorController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Current Position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current position: ${motorController.motorState.position} steps'),
            const SizedBox(height: 16),
            TextField(
              controller: _presetNameController,
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _presetNameController.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_presetNameController.text.isNotEmpty) {
                motorController.saveCurrentPositionAsPreset(_presetNameController.text);
                Navigator.of(context).pop();
                _presetNameController.clear();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Build status item
  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    String subtitle, {
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Build stats row
  Widget _buildStatsRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get motor status color
  Color _getStatusColor(MotorStatus status) {
    switch (status) {
      case MotorStatus.idle:
        return Colors.green;
      case MotorStatus.moving:
        return Colors.blue;
      case MotorStatus.error:
        return Colors.red;
      case MotorStatus.disabled:
        return Colors.grey;
    }
  }
}
