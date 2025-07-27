# PlantUML Architecture Diagrams

This folder contains comprehensive PlantUML diagrams documenting the modular architecture of the ESP32 Stepper Motor BLE Controller project.

## 📋 Diagram Overview

### 1. `component_architecture.puml` - Complete System View
**Purpose**: Comprehensive overview showing all components, their internal structure, and relationships

**Contains**:
- Application layer (main.c)
- All 4 components with their files and APIs
- Hardware abstraction layer
- External interfaces (mobile app, debug console)
- Complete dependency relationships
- Build system dependencies

**Use Case**: Understanding the overall system architecture and component interactions

### 2. `component_dependencies.puml` - Simplified Dependencies
**Purpose**: Clean view of component relationships without implementation details

**Contains**:
- Component-to-component dependencies
- ESP-IDF framework dependencies  
- Hardware abstraction relationships
- Simplified dependency flow

**Use Case**: Quick understanding of how components depend on each other

### 3. `deployment_diagram.puml` - Hardware-Software Mapping
**Purpose**: Shows how software components map to physical hardware

**Contains**:
- ESP32 board with software artifacts
- External hardware (motor driver, motor, LEDs)
- Power supply connections
- Communication interfaces (BLE, UART)
- GPIO pin mappings

**Use Case**: Understanding hardware connections and deployment architecture

### 4. `class_diagram.puml` - Data Structures and APIs
**Purpose**: Detailed view of data structures, enumerations, and API interfaces

**Contains**:
- Main data structures (stepper_motor_t, etc.)
- Enumerations for commands and status
- API interface definitions
- Configuration constants
- Relationships between structures

**Use Case**: Understanding data flow and API design

### 5. `enhanced_class_diagram.puml` - Complete Class Structure
**Purpose**: Comprehensive class diagram with all components, interfaces, and relationships

**Contains**:
- All classes organized by component packages
- Interface definitions for each component
- Internal data structures and states
- Configuration classes and enumerations
- Complete relationship mapping with multiplicity
- Detailed notes explaining key structures

**Use Case**: Deep technical understanding of object relationships and system architecture

### 6. `structure_overview.puml` - Core Data Structures Focus
**Purpose**: Simplified view focusing on the main data structures and their memory layout

**Contains**:
- Core stepper_motor_t structure with field details
- Control enumerations and their values
- Configuration constants and specifications
- Memory size annotations
- Data flow relationships
- Runtime vs compile-time data distinction

**Use Case**: Understanding data organization, memory usage, and structure relationships

### 7. `system_state_machine.puml` - System-Level State Machine
**Purpose**: Complete system state transitions and lifecycle management

**Contains**:
- All system states (INIT, READY, RUNNING, ERROR, TESTING)
- State entry/exit actions and activities
- Transition conditions and triggers
- Error handling and recovery flows
- Initialization sequence details
- Test suite integration

**Use Case**: Understanding system behavior, startup sequence, and error recovery

### 8. `motor_state_machine.puml` - Motor Control State Machine
**Purpose**: Detailed motor control states and command processing

**Contains**:
- Motor states (DISABLED, IDLE, MOVING, ERROR)
- Command processing substates within MOVING
- Step sequence generation logic
- Fault detection and recovery
- Speed control and position limits
- Thread-safe queue operations

**Use Case**: Understanding motor control logic, step generation, and fault handling

### 9. `ble_state_machine.puml` - BLE Connection State Machine
**Purpose**: BLE peripheral behavior and connection management

**Contains**:
- BLE connection lifecycle (INIT, ADVERTISING, CONNECTED, DISCONNECTED)
- GATT service substates during connection
- Event-driven transitions and callbacks
- Auto-recovery and error handling
- Advertising parameters and timing
- Service request processing

**Use Case**: Understanding BLE behavior, connection handling, and service operations

### 10. `combined_state_overview.puml` - Integrated State Overview
**Purpose**: High-level view showing interaction between all state machines

**Contains**:
- System, Motor, and BLE state machines in one view
- Inter-system dependencies and synchronization
- Concurrent task operations
- Real-time timing constraints
- Cross-system event flows
- Parallel state execution

**Use Case**: Understanding system-wide behavior and component interactions

### 11. `system_startup_activity.puml` - System Initialization Activity Flow
**Purpose**: Complete system startup sequence with swimlanes and decision points

**Contains**:
- Step-by-step initialization process (NVS → Motor → BLE → Tasks)
- Error handling and retry mechanisms for each component
- Parallel test execution flow (if enabled)
- Task creation and system readiness validation
- Fork/join activities showing concurrent operations
- Timeout and failure conditions

**Use Case**: Understanding boot sequence, debugging initialization failures

### 12. `motor_command_activity.puml` - Motor Command Processing Flow
**Purpose**: End-to-end motor command execution from BLE to hardware

**Contains**:
- BLE GATT characteristic write handling
- Command parsing and LED indication logic
- FreeRTOS queue-based command distribution
- Motor task command processing switch logic
- Real-time step generation and position tracking
- Fault detection during movement execution
- BLE notification updates for position changes

**Use Case**: Understanding command flow, debugging motor control issues

### 13. `ble_communication_activity.puml` - BLE Interaction Activity Flow
**Purpose**: Complete BLE communication lifecycle and GATT operations

**Contains**:
- Advertising startup and connection handling
- Service discovery from client perspective
- All GATT characteristic operations (read/write/notify)
- LED and Motor service request processing
- Visual feedback patterns for different commands
- Connection error handling and auto-recovery
- Notification subscription management

**Use Case**: Understanding BLE behavior, debugging communication issues

### 14. `error_handling_activity.puml` - Error Recovery Activity Flow
**Purpose**: Comprehensive error detection, classification, and recovery procedures

**Contains**:
- Multi-threaded fault detection (motor, BLE, system, memory)
- Error classification by type and severity
- Component-specific recovery strategies
- Retry mechanisms with backoff and limits
- System health validation after recovery
- Safe mode operation for critical failures
- Resource cleanup and system restart procedures

**Use Case**: Understanding fault tolerance, debugging system reliability

### 15. `test_execution_activity.puml` - Test Suite Activity Flow
**Purpose**: Complete motor testing workflow when CONFIG_ENABLE_MOTOR_TESTS is enabled

**Contains**:
- Parallel execution of all test categories
- Hardware validation (GPIO, driver response)
- Movement testing (forward, backward, homing)
- Position accuracy testing at multiple points
- Speed variation testing with timing validation
- Test result collection and pass/fail analysis
- LED visual feedback for test results

**Use Case**: Understanding test procedures, validating motor functionality

### 16. `combined_activity_overview.puml` - High-Level Activity Integration
**Purpose**: System-wide activity flow showing all major processes

**Contains**:
- Complete system lifecycle from boot to operation
- Concurrent runtime operations (monitoring, BLE, motor)
- Inter-task communication patterns and data flows
- Error handling integration across all components
- Real-time timing constraints and requirements
- System state integration with activity flows

**Use Case**: Understanding overall system behavior and process interactions

### 17. `system_startup_sequence.puml` - System Initialization Sequence
**Purpose**: Time-ordered initialization interactions between all system components

**Contains**:
- Sequential startup flow (NVS → Motor → BLE → Tasks)
- Alternative flows for initialization failures and recovery
- Parallel test execution with timing interactions
- Task creation and activation sequences
- System status transitions and logging
- Error handling with activation boxes

**Use Case**: Understanding boot timing, debugging initialization issues

### 18. `motor_command_sequence.puml` - Motor Command Processing Sequence  
**Purpose**: Complete command execution flow from BLE client to hardware

**Contains**:
- BLE GATT characteristic write handling with timing
- LED visual feedback patterns and GPIO interactions
- FreeRTOS queue operations with timeout handling
- Motor task command processing and execution loops
- Real-time step generation with hardware pin control
- BLE notification updates and subscription management
- Alternative command types (STOP, HOME, SPEED) with different flows

**Use Case**: Understanding command latency, debugging motor control timing

### 19. `ble_connection_sequence.puml` - BLE Communication Lifecycle
**Purpose**: Complete BLE interaction from advertising to disconnection

**Contains**:
- BLE stack initialization and service registration
- Advertising phase with connection establishment
- Service discovery from client perspective
- GATT operations (read/write/notify) with detailed interactions
- LED and Motor service request processing
- Real-time notification flows with subscription management
- Connection termination and auto-recovery sequences

**Use Case**: Understanding BLE timing, debugging communication issues

### 20. `error_recovery_sequence.puml` - Error Handling & Recovery Sequence
**Purpose**: Complete fault detection and recovery interaction flows

**Contains**:
- Multi-threaded fault detection with timing constraints
- Error classification and severity determination
- Motor hardware fault recovery with retry mechanisms
- BLE stack error handling and restart procedures
- System resource monitoring and memory management
- Post-recovery validation and enhanced monitoring
- Safe mode operations for critical failures

**Use Case**: Understanding fault tolerance, debugging recovery procedures

### 21. `test_execution_sequence.puml` - Test Suite Execution Sequence
**Purpose**: Complete motor testing workflow with parallel execution

**Contains**:
- Test suite initialization and coordination
- Parallel execution of all test categories with timing
- Hardware validation with GPIO testing sequences
- Movement, accuracy, and speed testing interactions
- Test result analysis and pass/fail determination
- LED visual feedback for test outcomes
- Test cleanup and system state restoration

**Use Case**: Understanding test procedures, debugging test failures

### 22. `combined_sequence_overview.puml` - System-Wide Sequence Integration
**Purpose**: High-level view of all major system interactions over time

**Contains**:
- Complete system lifecycle from boot to operation
- Concurrent sequence execution (user operations, monitoring, BLE management)
- Error recovery sequences integrated with normal operations
- Real-time timing constraints and data flow directions
- System state synchronization points and coordination
- Optional test execution integrated with main flows

**Use Case**: Understanding overall system behavior and interaction patterns

## 🔧 How to Use These Diagrams

### Viewing Online
1. Copy the content of any `.puml` file
2. Paste into [PlantUML Online Server](http://www.plantuml.com/plantuml/uml/)
3. Generate PNG/SVG for documentation

### Local Setup
```bash
# Install PlantUML
npm install -g node-plantuml
# or use Java version

# Generate diagrams
plantuml *.puml

# Generate specific format
plantuml -tpng component_architecture.puml
```

### VS Code Extension
Install "PlantUML" extension for real-time preview and editing.

## 📊 Diagram Purpose by Audience

### **Software Architects**
- `component_architecture.puml` - Complete system design
- `component_dependencies.puml` - Dependency analysis

### **Hardware Engineers** 
- `deployment_diagram.puml` - Hardware connections
- `component_architecture.puml` - Hardware interfaces

### **Software Developers**
- `class_diagram.puml` - Data structures and APIs
- `component_dependencies.puml` - Component interfaces
- `motor_state_machine.puml` - Control logic implementation
- `enhanced_class_diagram.puml` - Complete object model

### **System Integrators**
- `deployment_diagram.puml` - Physical connections
- `component_architecture.puml` - External interfaces
- `combined_state_overview.puml` - System interactions

### **Project Managers**
- `component_dependencies.puml` - Module relationships
- `deployment_diagram.puml` - System overview
- `system_state_machine.puml` - System lifecycle

### **Embedded Engineers**
- `motor_state_machine.puml` - Real-time control logic
- `structure_overview.puml` - Memory organization
- `ble_state_machine.puml` - Communication protocols
- `motor_command_activity.puml` - Command execution flow
- `error_handling_activity.puml` - Fault tolerance implementation

### **Test Engineers**
- `test_execution_activity.puml` - Complete test procedures
- `motor_command_activity.puml` - Command validation flow
- `error_handling_activity.puml` - Recovery testing scenarios
- `system_startup_activity.puml` - Initialization testing

### **Debug/Support Teams**
- `combined_activity_overview.puml` - System-wide behavior
- `error_handling_activity.puml` - Troubleshooting guide
- `ble_communication_activity.puml` - Communication debugging
- `system_startup_activity.puml` - Boot sequence analysis
- `error_recovery_sequence.puml` - Fault diagnosis and recovery
- `combined_sequence_overview.puml` - System interaction analysis

### **Performance Engineers**
- `motor_command_sequence.puml` - Command execution timing
- `ble_connection_sequence.puml` - Communication performance
- `system_startup_sequence.puml` - Boot time analysis
- `combined_sequence_overview.puml` - Real-time constraints

### **Integration Teams**
- `system_startup_sequence.puml` - Component integration order
- `ble_connection_sequence.puml` - BLE stack integration
- `test_execution_sequence.puml` - Integration testing procedures
- `combined_sequence_overview.puml` - System-wide coordination

## 🎯 Key Architectural Insights

### Modular Design
- Each component is self-contained with clear boundaries
- Standard ESP-IDF component structure throughout
- Clean separation between hardware and software layers

### Dependency Management
- Main application coordinates all components
- Common component provides shared configuration
- No circular dependencies between components

### Hardware Abstraction
- GPIO operations abstracted through driver layer
- Hardware configuration centralized in common component
- Easy to port to different hardware platforms

### Communication Patterns
- **Synchronous**: Direct API calls for immediate operations
- **Asynchronous**: FreeRTOS queues for motor commands  
- **Event-driven**: BLE callbacks and notifications

### State Machine Design
- **Hierarchical states**: Complex behaviors broken into substates
- **Concurrent execution**: Multiple state machines running in parallel
- **Event synchronization**: Cross-system state coordination
- **Error propagation**: Fault states cascade through system levels
- **Real-time constraints**: Timing requirements for state transitions

### Activity Flow Patterns
- **Swimlane organization**: Clear responsibility separation between components
- **Fork/Join concurrency**: Parallel execution of independent activities
- **Decision diamonds**: Conditional logic and error handling branches
- **Loop constructs**: Repeat-until and while-do patterns for continuous operations
- **Partition grouping**: Logical activity clustering within processes
- **Exception flows**: Error handling and recovery activity paths

### Sequence Interaction Patterns
- **Time-ordered messaging**: Chronological interaction flows between participants
- **Activation boxes**: Component lifelines showing when objects are active
- **Alternative flows**: Conditional branches with alt/else constructs
- **Parallel execution**: Concurrent operations with par/and constructs
- **Loop interactions**: Repeated message exchanges with timing constraints
- **Optional behaviors**: Conditional flows with opt constructs
- **Message synchronization**: Request/response patterns with return messages

## 📝 Maintaining These Diagrams

### When to Update
- Adding new components
- Changing component dependencies
- Modifying hardware connections
- API changes or new interfaces

### Best Practices
1. Keep diagrams synchronized with code
2. Use consistent naming with source files
3. Include notes for complex relationships
4. Validate diagrams render correctly
5. Update documentation when diagrams change

## 🔄 Integration with Documentation

These diagrams complement:
- **README.md** - Project overview and quick start
- **MODULAR_ARCHITECTURE.md** - Detailed architecture explanation
- **Component READMEs** - Individual component documentation

Together, they provide complete architectural documentation suitable for:
- Code reviews and design discussions
- Onboarding new team members
- System maintenance and evolution
- Technical documentation and presentations 