import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/led_controller.dart';
import '../controllers/connection_controller.dart';

/// LED control widget with patterns and effects
class LedControlWidget extends StatelessWidget {
  const LedControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LedController, ConnectionController>(
      builder: (context, ledController, connectionController, child) {
        final isConnected = connectionController.isConnected;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Individual LED Controls Card
            _buildIndividualControlsCard(context, ledController, isConnected),
            
            const SizedBox(height: 16),
            
            // LED Patterns Card
            _buildPatternsCard(context, ledController, isConnected),
            
            const SizedBox(height: 16),
            
            // Quick Actions Card
            _buildQuickActionsCard(context, ledController, isConnected),
            
            const SizedBox(height: 16),
            
            // Status Card
            _buildStatusCard(context, ledController),
          ],
        );
      },
    );
  }

  /// Build individual LED controls card
  Widget _buildIndividualControlsCard(
    BuildContext context,
    LedController ledController,
    bool isConnected,
  ) {
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
                  'Individual LED Control',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // LED switches
            ...List.generate(4, (index) {
              final ledNumber = index + 1;
              final isOn = ledController.ledState.getLed(index);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOn
                            ? _getLedColor(index)
                            : Colors.grey.withOpacity(0.3),
                        border: Border.all(
                          color: isOn
                              ? _getLedColor(index).withOpacity(0.8)
                              : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$ledNumber',
                          style: TextStyle(
                            color: isOn ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Text(
                        'LED $ledNumber',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    
                    Switch(
                      value: isOn,
                      onChanged: isConnected ? (value) {
                        ledController.setLed(index, value);
                      } : null,
                      activeColor: _getLedColor(index),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    IconButton(
                      onPressed: isConnected ? () {
                        ledController.toggleLed(index);
                      } : null,
                      icon: const Icon(Icons.flip),
                      tooltip: 'Toggle LED $ledNumber',
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build patterns card
  Widget _buildPatternsCard(
    BuildContext context,
    LedController ledController,
    bool isConnected,
  ) {
    final patterns = ledController.getAvailablePatterns();
    final patternNames = ledController.getPatternDisplayNames();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'LED Patterns',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (ledController.patternRunning)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Running',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Current pattern info
            if (ledController.patternRunning && ledController.currentPattern != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Running: ${patternNames[ledController.currentPattern!] ?? ledController.currentPattern!}',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: ledController.stopPattern,
                      child: const Text('Stop'),
                    ),
                  ],
                ),
              ),
            
            if (ledController.patternRunning) const SizedBox(height: 16),
            
            // Pattern selection
            Text(
              'Available Patterns',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: patterns.map((pattern) {
                return ActionChip(
                  label: Text(patternNames[pattern] ?? pattern),
                  onPressed: isConnected && !ledController.patternRunning ? () {
                    ledController.startPattern(pattern);
                  } : null,
                  backgroundColor: ledController.currentPattern == pattern
                      ? Colors.blue.withOpacity(0.2)
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick actions card
  Widget _buildQuickActionsCard(
    BuildContext context,
    LedController ledController,
    bool isConnected,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // All LEDs controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? ledController.turnAllOn : null,
                    icon: const Icon(Icons.lightbulb),
                    label: const Text('All ON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? ledController.turnAllOff : null,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('All OFF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Test and notification actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isConnected ? ledController.testAllLeds : null,
                    icon: const Icon(Icons.psychology),
                    label: const Text('Test All'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isConnected ? () {
                      _showNotificationDialog(context, ledController);
                    } : null,
                    icon: const Icon(Icons.notifications),
                    label: const Text('Flash'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build status card
  Widget _buildStatusCard(BuildContext context, LedController ledController) {
    final status = ledController.getLedStatus();
    
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
                  'LED Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // LED status grid
            Row(
              children: List.generate(4, (index) {
                final ledNumber = index + 1;
                final isOn = status['led${ledNumber}'] as bool;
                
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                    padding: const EdgeInsets.all(12),
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
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LED$ledNumber',
                          style: Theme.of(context).textTheme.bodySmall,
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
            
            // Additional status info
            if (ledController.patternRunning) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pattern'),
                  Text(
                    status['currentPattern'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Last Update'),
                Text(
                  _formatTimestamp(DateTime.parse(status['lastUpdate'])),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show notification flash dialog
  void _showNotificationDialog(BuildContext context, LedController ledController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flash Notification'),
        content: const Text('Select notification type to flash LEDs:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ledController.flashNotification('success');
            },
            child: const Text('Success'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ledController.flashNotification('warning');
            },
            child: const Text('Warning'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ledController.flashNotification('error');
            },
            child: const Text('Error'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ledController.flashNotification('info');
            },
            child: const Text('Info'),
          ),
        ],
      ),
    );
  }

  /// Get LED color by index
  Color _getLedColor(int index) {
    const colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
    ];
    return colors[index % colors.length];
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
