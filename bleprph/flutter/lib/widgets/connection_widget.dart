import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/connection_controller.dart';
import '../models/motor_models.dart';

/// Connection management widget
class ConnectionWidget extends StatelessWidget {
  final bool compact;
  
  const ConnectionWidget({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionController>(
      builder: (context, controller, child) {
        if (compact) {
          return _buildCompactView(context, controller);
        } else {
          return _buildFullView(context, controller);
        }
      },
    );
  }

  /// Build compact connection view
  Widget _buildCompactView(BuildContext context, ConnectionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getStatusColor(controller.connectionState),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              controller.connectionState.displayName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            if (controller.isConnected)
              Text(
                controller.formattedConnectionDuration,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        
        if (controller.connectedDeviceName != null) ...[
          const SizedBox(height: 4),
          Text(
            'Device: ${controller.connectedDeviceName}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
        
        if (controller.hasError) ...[
          const SizedBox(height: 4),
          Text(
            controller.errorMessage ?? 'Unknown error',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,
            ),
          ),
        ],
        
        const SizedBox(height: 8),
        
        Row(
          children: [
            if (controller.canConnect)
              ElevatedButton.icon(
                onPressed: controller.connect,
                icon: const Icon(Icons.bluetooth, size: 16),
                label: const Text('Connect'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              )
            else if (controller.isConnected)
              ElevatedButton.icon(
                onPressed: controller.disconnect,
                icon: const Icon(Icons.bluetooth_disabled, size: 16),
                label: const Text('Disconnect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              )
            else if (controller.isConnecting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ],
    );
  }

  /// Build full connection view
  Widget _buildFullView(BuildContext context, ConnectionController controller) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.bluetooth,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bluetooth Connection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(controller.connectionState),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.connectionState.displayName,
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
            
            // Connection info
            if (controller.isConnected) ...[
              _buildInfoRow(
                context,
                'Device',
                controller.connectedDeviceName ?? 'Unknown',
              ),
              _buildInfoRow(
                context,
                'Connected for',
                controller.formattedConnectionDuration,
              ),
              _buildInfoRow(
                context,
                'Auto-reconnect',
                controller.autoReconnectEnabled ? 'Enabled' : 'Disabled',
              ),
            ] else if (controller.hasError) ...[
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
                        controller.errorMessage ?? 'Connection error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (controller.reconnectAttempts > 0) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                'Reconnect attempts',
                '${controller.reconnectAttempts}/3',
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Control buttons
            Row(
              children: [
                if (controller.canConnect) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.connect,
                      icon: const Icon(Icons.bluetooth),
                      label: const Text('Connect'),
                    ),
                  ),
                ] else if (controller.isConnected) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.disconnect,
                      icon: const Icon(Icons.bluetooth_disabled),
                      label: const Text('Disconnect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (controller.isConnecting) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Connecting...'),
                        ],
                      ),
                    ),
                  ),
                ],
                
                if (controller.isConnected) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: controller.testConnection,
                    icon: const Icon(Icons.network_check, size: 18),
                    label: const Text('Test'),
                  ),
                ],
              ],
            ),
            
            // Advanced options
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Advanced Options'),
              children: [
                SwitchListTile(
                  title: const Text('Auto-reconnect'),
                  subtitle: const Text('Automatically reconnect when connection is lost'),
                  value: controller.autoReconnectEnabled,
                  onChanged: controller.setAutoReconnect,
                ),
                
                if (controller.reconnectAttempts > 0)
                  ListTile(
                    title: const Text('Reset Reconnect Counter'),
                    subtitle: Text('Current attempts: ${controller.reconnectAttempts}'),
                    trailing: TextButton(
                      onPressed: controller.resetReconnectAttempts,
                      child: const Text('Reset'),
                    ),
                  ),
                
                ListTile(
                  title: const Text('Force Reconnect'),
                  subtitle: const Text('Disconnect and reconnect immediately'),
                  trailing: TextButton(
                    onPressed: controller.isConnected ? controller.forceReconnect : null,
                    child: const Text('Reconnect'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build information row
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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

  /// Get status color for connection state
  Color _getStatusColor(ConnectionState state) {
    switch (state) {
      case ConnectionState.connected:
        return Colors.green;
      case ConnectionState.connecting:
      case ConnectionState.scanning:
        return Colors.orange;
      case ConnectionState.error:
        return Colors.red;
      case ConnectionState.disconnected:
        return Colors.grey;
    }
  }
}
