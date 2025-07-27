import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/connection_controller.dart';
import '../services/ble_service.dart';

/// Debug console widget for monitoring and troubleshooting
class DebugConsoleWidget extends StatefulWidget {
  const DebugConsoleWidget({super.key});

  @override
  State<DebugConsoleWidget> createState() => _DebugConsoleWidgetState();
}

class _DebugConsoleWidgetState extends State<DebugConsoleWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _logMessages = [];
  bool _autoScroll = true;
  bool _showTimestamps = true;
  String _filterText = '';
  final TextEditingController _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupLogListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  /// Setup log message listener
  void _setupLogListener() {
    BleService().logStream.listen((message) {
      if (mounted) {
        setState(() {
          _logMessages.add(message);
          
          // Keep only last 500 messages to prevent memory issues
          if (_logMessages.length > 500) {
            _logMessages.removeAt(0);
          }
        });
        
        // Auto-scroll to bottom if enabled
        if (_autoScroll && _scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredMessages = _getFilteredMessages();
    
    return Column(
      children: [
        // Console controls
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.terminal, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Debug Console',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${filteredMessages.length} messages',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Filter and controls
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _filterController,
                        decoration: const InputDecoration(
                          labelText: 'Filter messages',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _filterText = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        _filterController.clear();
                        setState(() {
                          _filterText = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear filter',
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Toggle controls
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Auto-scroll'),
                        value: _autoScroll,
                        onChanged: (value) {
                          setState(() {
                            _autoScroll = value ?? true;
                          });
                        },
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Timestamps'),
                        value: _showTimestamps,
                        onChanged: (value) {
                          setState(() {
                            _showTimestamps = value ?? true;
                          });
                        },
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
                
                // Action buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _clearLog,
                      icon: const Icon(Icons.delete),
                      label: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _exportLog,
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                    ),
                    const SizedBox(width: 8),
                    Consumer<ConnectionController>(
                      builder: (context, controller, child) {
                        return ElevatedButton.icon(
                          onPressed: controller.isConnected ? _testConnection : null,
                          icon: const Icon(Icons.network_check),
                          label: const Text('Test'),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Console output
        Expanded(
          child: Card(
            elevation: 4,
            child: Column(
              children: [
                // Console header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.code, size: 16),
                      const SizedBox(width: 8),
                      const Text('Console Output'),
                      const Spacer(),
                      if (filteredMessages.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                          tooltip: 'Scroll to bottom',
                        ),
                    ],
                  ),
                ),
                
                // Console messages
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: filteredMessages.isEmpty
                        ? const Center(
                            child: Text(
                              'No log messages',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: filteredMessages.length,
                            itemBuilder: (context, index) {
                              final message = filteredMessages[index];
                              return _buildLogMessage(context, message, index);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Quick command panel
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Commands',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Consumer<ConnectionController>(
                  builder: (context, controller, child) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Connection Stats'),
                          onPressed: () => _logConnectionStats(controller),
                          avatar: const Icon(Icons.bluetooth, size: 16),
                        ),
                        ActionChip(
                          label: const Text('Test Connection'),
                          onPressed: controller.isConnected
                              ? () => _testConnection()
                              : null,
                          avatar: const Icon(Icons.network_check, size: 16),
                        ),
                        ActionChip(
                          label: const Text('Force Reconnect'),
                          onPressed: controller.isConnected
                              ? () => controller.forceReconnect()
                              : null,
                          avatar: const Icon(Icons.refresh, size: 16),
                        ),
                        ActionChip(
                          label: const Text('Reset Counters'),
                          onPressed: () => controller.resetReconnectAttempts(),
                          avatar: const Icon(Icons.restore, size: 16),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build individual log message
  Widget _buildLogMessage(BuildContext context, String message, int index) {
    final parts = message.split('] ');
    final hasTimestamp = parts.length > 1 && parts[0].startsWith('[');
    
    String timestamp = '';
    String content = message;
    
    if (hasTimestamp) {
      timestamp = parts[0] + ']';
      content = parts.sublist(1).join('] ');
    }
    
    // Determine message type and color
    Color textColor = Colors.white;
    Color? backgroundColor;
    
    if (content.contains('ERROR')) {
      textColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
    } else if (content.contains('WARNING') || content.contains('WARN')) {
      textColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
    } else if (content.contains('Connected') || content.contains('SUCCESS')) {
      textColor = Colors.green;
    } else if (content.contains('Connecting') || content.contains('Scanning')) {
      textColor = Colors.blue;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line number
          SizedBox(
            width: 40,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          
          // Timestamp
          if (_showTimestamps && hasTimestamp) ...[
            SizedBox(
              width: 80,
              child: Text(
                timestamp.substring(1, timestamp.length - 1),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message content
          Expanded(
            child: SelectableText(
              content,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get filtered messages based on search text
  List<String> _getFilteredMessages() {
    if (_filterText.isEmpty) {
      return _logMessages;
    }
    
    return _logMessages
        .where((message) => message.toLowerCase().contains(_filterText))
        .toList();
  }

  /// Clear log messages
  void _clearLog() {
    setState(() {
      _logMessages.clear();
    });
  }

  /// Export log to clipboard
  void _exportLog() {
    final logText = _logMessages.join('\n');
    Clipboard.setData(ClipboardData(text: logText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Log exported to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Test connection and log results
  void _testConnection() async {
    final controller = Provider.of<ConnectionController>(context, listen: false);
    final success = await controller.testConnection();
    
    setState(() {
      _logMessages.add(
        '[${DateTime.now().toIso8601String().substring(11, 19)}] '
        'Manual connection test: ${success ? 'PASSED' : 'FAILED'}',
      );
    });
  }

  /// Log connection statistics
  void _logConnectionStats(ConnectionController controller) {
    final stats = controller.getConnectionStats();
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    
    setState(() {
      _logMessages.add('[$timestamp] === Connection Statistics ===');
      stats.forEach((key, value) {
        _logMessages.add('[$timestamp] $key: $value');
      });
      _logMessages.add('[$timestamp] === End Statistics ===');
    });
  }
}
