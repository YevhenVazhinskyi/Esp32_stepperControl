import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/connection_controller.dart';
import '../controllers/motor_controller.dart';
import '../controllers/led_controller.dart';
import '../models/motor_models.dart';

/// Comprehensive status display widget
class StatusDisplayWidget extends StatefulWidget {
  const StatusDisplayWidget({super.key});

  @override
  State<StatusDisplayWidget> createState() => _StatusDisplayWidgetState();
}

class _StatusDisplayWidgetState extends State<StatusDisplayWidget> {
  bool _autoRefresh = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Auto-refresh toggle
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Auto-refresh'),
                const Spacer(),
                Switch(
                  value: _autoRefresh,
                  onChanged: (value) {
                    setState(() {
                      _autoRefresh = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Connection Status Card
        _buildConnectionStatusCard(context),
        
        const SizedBox(height: 16),
        
        // Motor Status Card
        _buildMotorStatusCard(context),
        
        const SizedBox(height: 16),
        
        // LED Status Card
        _buildLedStatusCard(context),
        
        const SizedBox(height: 16),
        
        // System Performance Card
        _buildSystemPerformanceCard(context),
      ],
    );
  }

  /// Build connection status card
  Widget _buildConnectionStatusCard(BuildContext context) {
    return Consumer<ConnectionController>(
      builder: (context, controller, child) {
        final stats = controller.getConnectionStats();
        
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bluetooth, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getConnectionStatusColor(controller.isConnected),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        controller.isConnected ? 'CONNECTED' : 'DISCONNECTED',
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
                
                _buildStatusGrid(context, [
                  _StatusItem(
                    'Status',
                    controller.connectionState.displayName,
                    icon: Icons.info,
                  ),
                  _StatusItem(
                    'Device',
                    stats['deviceName'] ?? 'Not connected',
                    icon: Icons.devices,
                  ),
                  _StatusItem(
                    'Duration',
                    stats['connectionDuration'] ?? '0s',
                    icon: Icons.timer,
                  ),
                  _StatusItem(
                    'Auto-reconnect',
                    stats['autoReconnectEnabled'] ? 'Enabled' : 'Disabled',
                    icon: Icons.autorenew,
                  ),
                  _StatusItem(
                    'Reconnect Attempts',
                    '${stats['reconnectAttempts']}',
                    icon: Icons.repeat,
                  ),
                  _StatusItem(
                    'Log Entries',
                    '${stats['logEntries']}',
                    icon: Icons.list,
                  ),
                ]),
                
                if (controller.hasError) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.errorMessage ?? 'Unknown error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build motor status card
  Widget _buildMotorStatusCard(BuildContext context) {
    return Consumer<MotorController>(
      builder: (context, controller, child) {
        final motorState = controller.motorState;
        final stats = controller.getMovementStats();
        final presets = controller.getAllPresets();
        
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.precision_manufacturing, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Motor Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getMotorStatusColor(motorState.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        motorState.status.displayName.toUpperCase(),
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
                
                // Current motor state
                _buildStatusGrid(context, [
                  _StatusItem(
                    'Position',
                    '${motorState.position} steps',
                    subtitle: '${motorState.positionMm.toStringAsFixed(1)} mm',
                    icon: Icons.my_location,
                  ),
                  _StatusItem(
                    'Target',
                    '${motorState.targetPosition} steps',
                    subtitle: '${motorState.targetPositionMm.toStringAsFixed(1)} mm',
                    icon: Icons.gps_fixed,
                  ),
                  _StatusItem(
                    'Speed',
                    '${motorState.speedMs} ms',
                    subtitle: 'per step',
                    icon: Icons.speed,
                  ),
                  _StatusItem(
                    'Progress',
                    '${motorState.progressPercent.toStringAsFixed(1)}%',
                    subtitle: '${motorState.position}/${200}',
                    icon: Icons.trending_up,
                  ),
                  _StatusItem(
                    'Status',
                    motorState.isEnabled ? 'Enabled' : 'Disabled',
                    subtitle: motorState.isFault ? 'FAULT' : 'OK',
                    icon: Icons.power,
                    valueColor: motorState.isFault ? Colors.red : null,
                  ),
                  _StatusItem(
                    'Moving',
                    motorState.isMoving ? 'Yes' : 'No',
                    subtitle: controller.isJogging ? 'Jogging' : 'Idle',
                    icon: Icons.directions_run,
                  ),
                ]),
                
                const SizedBox(height: 16),
                
                // Movement statistics
                ExpansionTile(
                  title: const Text('Movement Statistics'),
                  children: [
                    _buildStatusGrid(context, [
                      _StatusItem(
                        'Total Moves',
                        '${stats['totalMoves']}',
                        icon: Icons.trending_up,
                      ),
                      _StatusItem(
                        'Avg Position',
                        '${stats['averagePosition']} steps',
                        icon: Icons.bar_chart,
                      ),
                      _StatusItem(
                        'Max Position',
                        '${stats['maxPosition']} steps',
                        icon: Icons.keyboard_arrow_up,
                      ),
                      _StatusItem(
                        'Min Position',
                        '${stats['minPosition']} steps',
                        icon: Icons.keyboard_arrow_down,
                      ),
                      _StatusItem(
                        'Total Distance',
                        '${stats['totalDistance']} steps',
                        icon: Icons.straighten,
                      ),
                      _StatusItem(
                        'Custom Presets',
                        '${controller.customPresets.length}',
                        icon: Icons.bookmark,
                      ),
                    ]),
                  ],
                ),
                
                // Available presets
                if (presets.isNotEmpty)
                  ExpansionTile(
                    title: Text('Available Presets (${presets.length})'),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: presets.entries.map((entry) {
                          return Chip(
                            label: Text('${entry.key}: ${entry.value}'),
                            onDeleted: controller.customPresets.containsKey(entry.key) 
                                ? () => controller.deletePreset(entry.key) 
                                : null,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build LED status card
  Widget _buildLedStatusCard(BuildContext context) {
    return Consumer<LedController>(
      builder: (context, controller, child) {
        final status = controller.getLedStatus();
        final patterns = controller.getAvailablePatterns();
        
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'LED Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: controller.patternRunning ? Colors.blue : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        controller.patternRunning ? 'PATTERN ACTIVE' : 'MANUAL',
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
                
                // LED states grid
                Row(
                  children: List.generate(4, (index) {
                    final ledNumber = index + 1;
                    final isOn = status['led$ledNumber'] as bool;
                    
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isOn
                              ? _getLedColor(index).withOpacity(0.2)
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOn
                                ? _getLedColor(index)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                              color: isOn ? _getLedColor(index) : Colors.grey,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'LED $ledNumber',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              isOn ? 'ON' : 'OFF',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isOn ? _getLedColor(index) : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 16),
                
                // Pattern information
                if (controller.patternRunning && controller.currentPattern != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.play_circle_filled, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Pattern: ${controller.currentPattern}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Animation Step: ${status['animationStep']}',
                                style: TextStyle(
                                  color: Colors.blue.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Available patterns
                ExpansionTile(
                  title: Text('Available Patterns (${patterns.length})'),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: patterns.map((pattern) {
                        final displayNames = controller.getPatternDisplayNames();
                        return Chip(
                          label: Text(displayNames[pattern] ?? pattern),
                          backgroundColor: controller.currentPattern == pattern
                              ? Colors.blue.withOpacity(0.2)
                              : null,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build system performance card
  Widget _buildSystemPerformanceCard(BuildContext context) {
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
                  'System Performance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Consumer3<ConnectionController, MotorController, LedController>(
              builder: (context, connectionController, motorController, ledController, child) {
                final connectionStats = connectionController.getConnectionStats();
                final motorStats = motorController.getMovementStats();
                final activeLeds = _getActiveLedCount(ledController.ledState);
                
                return _buildStatusGrid(context, [
                  _StatusItem(
                    'Connection Uptime',
                    connectionStats['connectionDuration'] ?? '0s',
                    icon: Icons.timer,
                  ),
                  _StatusItem(
                    'Total Commands',
                    '${motorStats['totalMoves']}',
                    subtitle: 'Motor commands sent',
                    icon: Icons.send,
                  ),
                  _StatusItem(
                    'Active LEDs',
                    '$activeLeds/4',
                    subtitle: '${(activeLeds / 4 * 100).toStringAsFixed(0)}% usage',
                    icon: Icons.lightbulb,
                  ),
                  _StatusItem(
                    'Connection Quality',
                    connectionController.isConnected ? 'Good' : 'Poor',
                    subtitle: connectionController.hasError ? 'Error detected' : 'Stable',
                    icon: Icons.signal_cellular_4_bar,
                    valueColor: connectionController.isConnected ? Colors.green : Colors.red,
                  ),
                  _StatusItem(
                    'System Status',
                    'Running',
                    subtitle: DateTime.now().toIso8601String().substring(11, 19),
                    icon: Icons.computer,
                  ),
                  _StatusItem(
                    'App Version',
                    '1.0.0',
                    subtitle: 'ESP32 Motor Controller',
                    icon: Icons.info,
                  ),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build status grid layout
  Widget _buildStatusGrid(BuildContext context, List<_StatusItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: item.valueColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Get connection status color
  Color _getConnectionStatusColor(bool isConnected) {
    return isConnected ? Colors.green : Colors.red;
  }

  /// Get motor status color
  Color _getMotorStatusColor(MotorStatus status) {
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

  /// Get LED color by index
  Color _getLedColor(int index) {
    const colors = [Colors.red, Colors.green, Colors.blue, Colors.orange];
    return colors[index % colors.length];
  }

  /// Get count of active LEDs
  int _getActiveLedCount(LedState state) {
    int count = 0;
    if (state.led1) count++;
    if (state.led2) count++;
    if (state.led3) count++;
    if (state.led4) count++;
    return count;
  }

  /// Import MotorStatus enum
  
}

/// Status item data class
class _StatusItem {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? valueColor;

  const _StatusItem(
    this.label,
    this.value, {
    this.subtitle,
    required this.icon,
    this.valueColor,
  });
}
