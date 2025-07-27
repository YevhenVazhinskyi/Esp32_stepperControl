import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/connection_controller.dart';
import '../controllers/motor_controller.dart';
import '../controllers/led_controller.dart';
import '../widgets/connection_widget.dart';
import '../widgets/motor_control_widget.dart';
import '../widgets/led_control_widget.dart';
import '../widgets/status_display_widget.dart';
import '../widgets/debug_console_widget.dart';

/// Main application screen with tabbed interface
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionController()),
        ChangeNotifierProvider(create: (_) => MotorController()),
        ChangeNotifierProvider(create: (_) => LedController()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ESP32 Motor Controller'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 2,
          actions: [
            Consumer<ConnectionController>(
              builder: (context, controller, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getConnectionColor(controller.connectionState),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getConnectionIcon(controller.connectionState),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.connectionState.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            tabs: const [
              Tab(icon: Icon(Icons.home), text: 'Overview'),
              Tab(icon: Icon(Icons.precision_manufacturing), text: 'Motor'),
              Tab(icon: Icon(Icons.lightbulb), text: 'LEDs'),
              Tab(icon: Icon(Icons.analytics), text: 'Status'),
              Tab(icon: Icon(Icons.terminal), text: 'Debug'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildMotorTab(),
            _buildLedTab(),
            _buildStatusTab(),
            _buildDebugTab(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  /// Build overview tab with key information
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status Card
          Card(
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
                        'Connection',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const ConnectionWidget(compact: true),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick Motor Controls
          Card(
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
                        'Quick Controls',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildQuickControls(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // System Status Overview
          Card(
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
                        'System Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSystemStatus(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build motor control tab
  Widget _buildMotorTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: MotorControlWidget(),
    );
  }

  /// Build LED control tab
  Widget _buildLedTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: LedControlWidget(),
    );
  }

  /// Build status monitoring tab
  Widget _buildStatusTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: StatusDisplayWidget(),
    );
  }

  /// Build debug console tab
  Widget _buildDebugTab() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: DebugConsoleWidget(),
    );
  }

  /// Build quick motor controls
  Widget _buildQuickControls() {
    return Consumer<MotorController>(
      builder: (context, motorController, child) {
        return Consumer<ConnectionController>(
          builder: (context, connectionController, child) {
            final isConnected = connectionController.isConnected;
            
            return Column(
              children: [
                // Position display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Position:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${motorController.motorState.position} steps',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Quick action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isConnected ? motorController.homeMotor : null,
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
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
              ],
            );
          },
        );
      },
    );
  }

  /// Build system status overview
  Widget _buildSystemStatus() {
    return Consumer3<ConnectionController, MotorController, LedController>(
      builder: (context, connectionController, motorController, ledController, child) {
        return Column(
          children: [
            _buildStatusRow(
              'Connection',
              connectionController.isConnected ? 'Connected' : 'Disconnected',
              connectionController.isConnected ? Colors.green : Colors.red,
            ),
            const Divider(),
            _buildStatusRow(
              'Motor Status',
              motorController.motorState.status.displayName,
              _getMotorStatusColor(motorController.motorState.status),
            ),
            const Divider(),
            _buildStatusRow(
              'Motor Position',
              '${motorController.motorState.position} steps',
              Theme.of(context).colorScheme.onSurface,
            ),
            const Divider(),
            _buildStatusRow(
              'Active LEDs',
              _getActiveLedCount(ledController.ledState).toString(),
              Theme.of(context).colorScheme.onSurface,
            ),
          ],
        );
      },
    );
  }

  /// Build status row
  Widget _buildStatusRow(String label, String value, Color valueColor) {
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
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build floating action button based on current tab
  Widget? _buildFloatingActionButton() {
    switch (_currentTabIndex) {
      case 0: // Overview
        return Consumer<ConnectionController>(
          builder: (context, controller, child) {
            if (controller.isConnected) {
              return FloatingActionButton(
                onPressed: controller.disconnect,
                backgroundColor: Colors.red,
                child: const Icon(Icons.bluetooth_disabled, color: Colors.white),
              );
            } else {
              return FloatingActionButton(
                onPressed: controller.connect,
                child: const Icon(Icons.bluetooth),
              );
            }
          },
        );
      case 1: // Motor
        return Consumer<MotorController>(
          builder: (context, controller, child) {
            return FloatingActionButton(
              onPressed: controller.emergencyStop,
              backgroundColor: Colors.red,
              child: const Icon(Icons.emergency, color: Colors.white),
            );
          },
        );
      case 2: // LEDs
        return Consumer<LedController>(
          builder: (context, controller, child) {
            return FloatingActionButton(
              onPressed: controller.turnAllOff,
              child: const Icon(Icons.lightbulb_outline),
            );
          },
        );
      default:
        return null;
    }
  }

  /// Get connection status color
  Color _getConnectionColor(ConnectionState state) {
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

  /// Get connection status icon
  IconData _getConnectionIcon(ConnectionState state) {
    switch (state) {
      case ConnectionState.connected:
        return Icons.bluetooth_connected;
      case ConnectionState.connecting:
      case ConnectionState.scanning:
        return Icons.bluetooth_searching;
      case ConnectionState.error:
        return Icons.bluetooth_disabled;
      case ConnectionState.disconnected:
        return Icons.bluetooth;
    }
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

  /// Get count of active LEDs
  int _getActiveLedCount(LedState state) {
    int count = 0;
    if (state.led1) count++;
    if (state.led2) count++;
    if (state.led3) count++;
    if (state.led4) count++;
    return count;
  }
}
