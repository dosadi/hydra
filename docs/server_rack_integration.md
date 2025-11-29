# Server Rack Integration

## Overview

This document describes the server rack integration for Hydra accelerators, covering rack-mounted deployment, power and cooling management, network connectivity, and data center integration protocols for enterprise-scale deployment.

## Rack Architecture Overview

### Standard Rack Specifications
```
┌─────────────────────────────────────────────────────────────┐
│                    42U Server Rack                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │                Rack Management                       │    │
│  │  ├─ Rack PDU (Power Distribution Unit)             │    │
│  │  ├─ Rack Switch (Network Aggregation)              │    │
│  │  ├─ BMC/KVM (Baseboard Management Controller)      │    │
│  │  └─ Environmental Monitoring                       │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                Server Nodes (1U-4U)                  │    │
│  │  ├─ CPU Server (2U): Xeon + DDR4                    │    │
│  │  ├─ GPU Server (4U): Multiple GPUs + PCIe Gen4      │    │
│  │  ├─ Storage Server (2U): NVMe SSD arrays            │    │
│  │  └─ Hydra Server (2U): FPGA + High-speed I/O        │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                Hydra Accelerator Card                 │    │
│  │  ├─ PCIe Gen4 x16 connection                        │    │
│  │  ├─ Auxiliary power (75W-300W)                      │    │
│  │  ├─ High-speed networking (100G/400G)               │    │
│  │  └─ Management interface (I2C/SMBus)                │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Rack Unit Allocation
- **1U**: Network switches, management controllers
- **2U**: CPU servers, storage nodes, compact accelerators
- **4U**: GPU servers, high-power accelerators, storage arrays
- **Full Rack**: Multi-node clusters, disaggregated systems

## Power Distribution and Management

### Rack Power Specifications
```c
#define RACK_VOLTAGE_208V_3PH  208  // 208V 3-phase
#define RACK_VOLTAGE_480V_3PH  480  // 480V 3-phase (high-density)
#define RACK_POWER_MAX_KW      25   // Maximum per rack (varies by density)

struct rack_power_config {
    int voltage;           // Input voltage (V)
    int phases;            // Number of phases (1, 3)
    int max_power_kw;      // Maximum power capacity (kW)
    int redundancy;        // Power redundancy level (N, N+1, 2N)
    bool hot_swap;         // Hot-swap capability
};

struct hydra_power_rail {
    char name[32];         // Rail name ("12V_AUX", "3.3V", etc.)
    float voltage_nom;     // Nominal voltage (V)
    float voltage_tol;     // Tolerance (±%)
    float current_max;     // Maximum current (A)
    float power_max;       // Maximum power (W)
    bool hot_swap;         // Hot-swap capable
    int priority;          // Power sequencing priority
};
```

### Power Delivery Implementation
```c
static const struct hydra_power_rail hydra_power_rails[] = {
    {
        .name = "12V_AUX",
        .voltage_nom = 12.0,
        .voltage_tol = 5.0,
        .current_max = 25.0,    // 300W max
        .power_max = 300.0,
        .hot_swap = true,
        .priority = 1
    },
    {
        .name = "3.3V",
        .voltage_nom = 3.3,
        .voltage_tol = 5.0,
        .current_max = 50.0,    // 165W max
        .power_max = 165.0,
        .hot_swap = false,
        .priority = 2
    },
    {
        .name = "1.8V_CORE",
        .voltage_nom = 1.8,
        .voltage_tol = 3.0,
        .current_max = 100.0,   // 180W max
        .power_max = 180.0,
        .hot_swap = false,
        .priority = 3
    }
};

static int hydra_power_sequencing(struct hydra_dev *hdev)
{
    int err;

    // Power-on sequence (reverse priority order)
    for (int pri = 1; pri <= MAX_PRIORITY; pri++) {
        for (int i = 0; i < ARRAY_SIZE(hydra_power_rails); i++) {
            const struct hydra_power_rail *rail = &hydra_power_rails[i];

            if (rail->priority == pri) {
                err = hydra_enable_power_rail(hdev, rail);
                if (err) {
                    dev_err(&hdev->pdev->dev,
                           "Failed to enable power rail %s: %d\n",
                           rail->name, err);
                    goto power_off;
                }

                // Wait for stabilization
                msleep(rail->stabilization_ms);
            }
        }
    }

    return 0;

power_off:
    // Power-off sequence (forward priority order)
    for (int pri = MAX_PRIORITY; pri >= 1; pri--) {
        for (int i = 0; i < ARRAY_SIZE(hydra_power_rails); i++) {
            const struct hydra_power_rail *rail = &hydra_power_rails[i];
            if (rail->priority == pri) {
                hydra_disable_power_rail(hdev, rail);
            }
        }
    }

    return err;
}
```

### Power Monitoring and Telemetry
```c
struct hydra_power_telemetry {
    ktime_t timestamp;
    float voltage_12v_aux;
    float current_12v_aux;
    float voltage_3v3;
    float current_3v3;
    float voltage_1v8_core;
    float current_1v8_core;
    float temperature_fpga;
    float temperature_pcie;
    float power_total;
    bool overcurrent_12v;
    bool overcurrent_3v3;
    bool overcurrent_1v8;
    bool overtemp_fpga;
    bool overtemp_pcie;
};

static void hydra_power_monitor_work(struct work_struct *work)
{
    struct hydra_dev *hdev = container_of(work, struct hydra_dev,
                                         power_monitor_work.work);
    struct hydra_power_telemetry telemetry;

    // Read power rails
    telemetry.voltage_12v_aux = hydra_read_voltage(hdev, RAIL_12V_AUX);
    telemetry.current_12v_aux = hydra_read_current(hdev, RAIL_12V_AUX);
    telemetry.voltage_3v3 = hydra_read_voltage(hdev, RAIL_3V3);
    telemetry.current_3v3 = hydra_read_current(hdev, RAIL_3V3);
    telemetry.voltage_1v8_core = hydra_read_voltage(hdev, RAIL_1V8_CORE);
    telemetry.current_1v8_core = hydra_read_current(hdev, RAIL_1V8_CORE);

    // Calculate total power
    telemetry.power_total = (telemetry.voltage_12v_aux * telemetry.current_12v_aux) +
                           (telemetry.voltage_3v3 * telemetry.current_3v3) +
                           (telemetry.voltage_1v8_core * telemetry.current_1v8_core);

    // Read temperatures
    telemetry.temperature_fpga = hydra_read_temperature(hdev, TEMP_FPGA);
    telemetry.temperature_pcie = hydra_read_temperature(hdev, TEMP_PCIE);

    // Check thresholds
    telemetry.overcurrent_12v = telemetry.current_12v_aux > hydra_power_rails[0].current_max;
    telemetry.overcurrent_3v3 = telemetry.current_3v3 > hydra_power_rails[1].current_max;
    telemetry.overcurrent_1v8 = telemetry.current_1v8_core > hydra_power_rails[2].current_max;
    telemetry.overtemp_fpga = telemetry.temperature_fpga > TEMP_FPGA_MAX;
    telemetry.overtemp_pcie = telemetry.temperature_pcie > TEMP_PCIE_MAX;

    // Store telemetry
    hydra_store_telemetry(hdev, &telemetry);

    // Schedule next monitoring
    schedule_delayed_work(&hdev->power_monitor_work, HZ);
}
```

## Thermal Management

### Rack Cooling Architecture
```
Airflow Direction: Front → Rear (Standard)
┌─────────────────────────────────────────────────────────────┐
│                    Rack Cooling Zones                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │   Cold Aisle    │  │   Equipment     │  │  Hot Aisle  │  │
│  │   (18-22°C)     │  │   Zone          │  │   (35-45°C) │  │
│  │                 │  │   (24-32°C)     │  │             │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │                Server Cooling                        │    │
│  │  ├─ Front Fans: Intake from cold aisle              │    │
│  │  ├─ Rear Exhaust: Hot air to hot aisle              │    │
│  │  ├─ Internal Fans: Component cooling                 │    │
│  │  └─ Heat Sinks: Passive/active cooling               │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Hydra Thermal Design
```c
#define TEMP_FPGA_MAX       85.0   // °C
#define TEMP_PCIE_MAX       75.0   // °C
#define TEMP_MEMORY_MAX     95.0   // °C
#define TEMP_AMBIENT_MAX    35.0   // °C

struct hydra_thermal_zone {
    char name[32];
    float temperature;
    float max_temp;
    float hysteresis;
    int cooling_device;
    bool critical;
};

static const struct hydra_thermal_zone hydra_thermal_zones[] = {
    {
        .name = "FPGA Core",
        .max_temp = TEMP_FPGA_MAX,
        .hysteresis = 5.0,
        .cooling_device = COOLING_FAN_FPGA,
        .critical = true
    },
    {
        .name = "PCIe Interface",
        .max_temp = TEMP_PCIE_MAX,
        .hysteresis = 3.0,
        .cooling_device = COOLING_FAN_PCIE,
        .critical = false
    },
    {
        .name = "Memory",
        .max_temp = TEMP_MEMORY_MAX,
        .hysteresis = 10.0,
        .cooling_device = COOLING_FAN_MEMORY,
        .critical = true
    }
};

static int hydra_thermal_throttle(struct hydra_dev *hdev,
                                 struct hydra_thermal_zone *zone)
{
    int err;

    dev_warn(&hdev->pdev->dev, "Thermal throttling: %s at %.1f°C\n",
             zone->name, zone->temperature);

    // Reduce performance to lower temperature
    if (zone->critical) {
        // Emergency throttling
        err = hydra_set_performance_level(hdev, PERF_EMERGENCY);
        if (err)
            return err;

        // Increase fan speed
        err = hydra_set_fan_speed(hdev, zone->cooling_device, FAN_MAX_SPEED);
        if (err)
            return err;
    } else {
        // Gradual throttling
        err = hydra_adjust_performance(hdev, zone->temperature, zone->max_temp);
        if (err)
            return err;
    }

    return 0;
}
```

## Network Connectivity

### Rack Network Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                Rack Network Topology                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │                Spine Switches (Top-of-Rack)          │    │
│  │  ├─ 100G/400G uplinks to core network               │    │
│  │  ├─ 25G/100G downlinks to servers                   │    │
│  │  └─ Redundant power and management                  │    │
│  └─────────────────────────────────────────────────────┘    │
│           │                                                  │
│           │ 100G/400G                                        │
│           ▼                                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                Hydra Server Node                      │    │
│  │  ├─ PCIe Gen4 x16 to Hydra card                     │    │
│  │  ├─ 100G NIC for data networking                    │    │
│  │  ├─ 1G management network                           │    │
│  │  └─ BMC interface for out-of-band management        │    │
│  └─────────────────────────────────────────────────────┘    │
│           │                                                  │
│           │ PCIe Gen4 x16                                   │
│           ▼                                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                Hydra Accelerator Card                 │    │
│  │  ├─ 100G/400G Ethernet for RDMA/high-speed data     │    │
│  │  ├─ PCIe Gen4 x16 for host communication             │    │
│  │  ├─ Management interface (I2C/SMBus)                 │    │
│  │  └─ Debug/serial console                             │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### High-Speed Networking Implementation
```c
#define HYDRA_ETH_PORTS_MAX    4
#define HYDRA_ETH_SPEED_MAX    400000  // 400Gbps

struct hydra_ethernet_port {
    int port_id;
    int speed_mbps;           // Configured speed
    int max_speed_mbps;       // Maximum supported speed
    bool autoneg;             // Auto-negotiation enabled
    bool rdma_enabled;        // RDMA support
    bool pause_enabled;       // Flow control
    uint8_t mac_addr[6];      // MAC address
    char ifname[IFNAMSIZ];    // Network interface name
};

struct hydra_network_config {
    struct hydra_ethernet_port ports[HYDRA_ETH_PORTS_MAX];
    int num_ports;
    bool lldp_enabled;        // Link Layer Discovery Protocol
    bool dc_bcn_enabled;      // Data Center Bridging
    bool pfc_enabled;         // Priority Flow Control
    int mtu;                  // Maximum transmission unit
};

static int hydra_network_init(struct hydra_dev *hdev)
{
    struct hydra_network_config *net = &hdev->network;
    int err;

    // Initialize Ethernet ports
    for (int i = 0; i < net->num_ports; i++) {
        struct hydra_ethernet_port *port = &net->ports[i];

        // Configure port speed and features
        err = hydra_eth_configure_port(hdev, port);
        if (err) {
            dev_err(&hdev->pdev->dev,
                   "Failed to configure Ethernet port %d: %d\n", i, err);
            return err;
        }

        // Enable RDMA if supported
        if (port->rdma_enabled) {
            err = hydra_rdma_init(hdev, port);
            if (err) {
                dev_warn(&hdev->pdev->dev,
                        "RDMA initialization failed for port %d: %d\n", i, err);
                port->rdma_enabled = false;
            }
        }
    }

    // Configure network protocols
    if (net->lldp_enabled) {
        err = hydra_lldp_init(hdev);
        if (err)
            dev_warn(&hdev->pdev->dev, "LLDP initialization failed: %d\n", err);
    }

    if (net->dc_bcn_enabled) {
        err = hydra_dcb_init(hdev);
        if (err)
            dev_warn(&hdev->pdev->dev, "DCB initialization failed: %d\n", err);
    }

    return 0;
}
```

## Management Interfaces

### IPMI (Intelligent Platform Management Interface)
```c
#define IPMI_MAX_CHANNELS     16
#define IPMI_MAX_USERS       16

struct hydra_ipmi_config {
    uint8_t ipmi_version;      // IPMI version (2.0)
    uint8_t channel_count;     // Number of channels
    uint8_t user_count;        // Number of users
    bool encryption_enabled;   // Encryption support
    bool authentication_enabled; // Authentication support
    uint16_t udp_port;         // RMCP port (623)
};

static int hydra_ipmi_init(struct hydra_dev *hdev)
{
    struct hydra_ipmi_config *ipmi = &hdev->ipmi;
    int err;

    // Initialize IPMI interface
    err = ipmi_init(&hdev->ipmi.iface);
    if (err) {
        dev_err(&hdev->pdev->dev, "IPMI initialization failed: %d\n", err);
        return err;
    }

    // Configure channels
    for (int ch = 0; ch < ipmi->channel_count; ch++) {
        err = ipmi_channel_configure(&hdev->ipmi.iface, ch,
                                   IPMI_CHANNEL_TYPE_SYSTEM);
        if (err) {
            dev_err(&hdev->pdev->dev,
                   "IPMI channel %d configuration failed: %d\n", ch, err);
            return err;
        }
    }

    // Configure users
    for (int user = 0; user < ipmi->user_count; user++) {
        err = ipmi_user_configure(&hdev->ipmi.iface, user,
                                IPMI_USER_PRIVILEGE_ADMIN);
        if (err) {
            dev_err(&hdev->pdev->dev,
                   "IPMI user %d configuration failed: %d\n", user, err);
            return err;
        }
    }

    // Register IPMI handlers
    ipmi_register_handler(&hdev->ipmi.iface, IPMI_CMD_GET_DEVICE_ID,
                         hydra_ipmi_get_device_id);
    ipmi_register_handler(&hdev->ipmi.iface, IPMI_CMD_GET_SENSOR_READING,
                         hydra_ipmi_get_sensor_reading);
    ipmi_register_handler(&hdev->ipmi.iface, IPMI_CMD_SET_POWER_STATE,
                         hydra_ipmi_set_power_state);

    dev_info(&hdev->pdev->dev, "IPMI interface initialized\n");
    return 0;
}
```

### Redfish API Integration
```c
#define REDFISH_API_VERSION   "1.0.0"
#define REDFISH_PORT         443

struct hydra_redfish_config {
    char api_version[16];
    int https_port;
    bool authentication_enabled;
    bool ssl_enabled;
    char certificate_path[PATH_MAX];
    char private_key_path[PATH_MAX];
};

static int hydra_redfish_init(struct hydra_dev *hdev)
{
    struct hydra_redfish_config *redfish = &hdev->redfish;
    int err;

    // Initialize HTTPS server
    err = redfish_https_init(redfish->https_port);
    if (err) {
        dev_err(&hdev->pdev->dev, "Redfish HTTPS init failed: %d\n", err);
        return err;
    }

    // Load SSL certificates
    if (redfish->ssl_enabled) {
        err = redfish_ssl_configure(redfish->certificate_path,
                                  redfish->private_key_path);
        if (err) {
            dev_err(&hdev->pdev->dev, "Redfish SSL config failed: %d\n", err);
            return err;
        }
    }

    // Register Redfish endpoints
    redfish_register_endpoint("/redfish/v1/Systems/Hydra",
                            hydra_redfish_system_handler);
    redfish_register_endpoint("/redfish/v1/Chassis/Hydra",
                            hydra_redfish_chassis_handler);
    redfish_register_endpoint("/redfish/v1/Systems/Hydra/Processors",
                            hydra_redfish_processors_handler);
    redfish_register_endpoint("/redfish/v1/Systems/Hydra/Memory",
                            hydra_redfish_memory_handler);

    dev_info(&hdev->pdev->dev, "Redfish API initialized on port %d\n",
             redfish->https_port);
    return 0;
}
```

## Rack-Scale Management

### Rack Management Controller Integration
```c
struct rack_management_config {
    char bmc_ip[16];          // BMC IP address
    int bmc_port;             // BMC port (default 623 for IPMI)
    char username[32];        // BMC username
    char password[32];        // BMC password
    bool ipmi_enabled;        // IPMI support
    bool redfish_enabled;     // Redfish support
    bool snmp_enabled;        // SNMP support
};

static int hydra_rack_discovery(struct hydra_dev *hdev)
{
    struct rack_management_config *rack = &hdev->rack;
    int err;

    // Discover rack management controller
    err = rack_bmc_discover(rack->bmc_ip, rack->bmc_port);
    if (err) {
        dev_warn(&hdev->pdev->dev, "BMC discovery failed: %d\n", err);
        return err;
    }

    // Authenticate with BMC
    err = rack_bmc_authenticate(rack->username, rack->password);
    if (err) {
        dev_err(&hdev->pdev->dev, "BMC authentication failed: %d\n", err);
        return err;
    }

    // Query rack information
    err = rack_query_inventory(hdev);
    if (err) {
        dev_warn(&hdev->pdev->dev, "Rack inventory query failed: %d\n", err);
    }

    // Register for alerts
    err = rack_register_alerts(hdev, hydra_rack_alert_handler);
    if (err) {
        dev_warn(&hdev->pdev->dev, "Alert registration failed: %d\n", err);
    }

    dev_info(&hdev->pdev->dev, "Connected to rack BMC at %s:%d\n",
             rack->bmc_ip, rack->bmc_port);
    return 0;
}
```

### Environmental Monitoring
```c
struct rack_environmental_data {
    ktime_t timestamp;
    float temperature_inlet;    // Cold aisle temperature (°C)
    float temperature_outlet;   // Hot aisle temperature (°C)
    float humidity;             // Relative humidity (%)
    float air_pressure;         // Air pressure (kPa)
    float rack_power_total;     // Total rack power (kW)
    float rack_power_available; // Available power capacity (kW)
    bool fan_failure;           // Fan failure detected
    bool power_redundancy_lost; // Power redundancy lost
    bool temperature_alarm;     // Temperature alarm active
};

static void hydra_rack_monitor_work(struct work_struct *work)
{
    struct hydra_dev *hdev = container_of(work, struct hydra_dev,
                                         rack_monitor_work.work);
    struct rack_environmental_data env_data;
    int err;

    // Query environmental data from BMC
    err = rack_query_environmental(&env_data);
    if (err) {
        dev_warn(&hdev->pdev->dev, "Environmental query failed: %d\n", err);
        goto reschedule;
    }

    // Check thresholds
    if (env_data.temperature_inlet > TEMP_INLET_MAX) {
        dev_warn(&hdev->pdev->dev, "High inlet temperature: %.1f°C\n",
                env_data.temperature_inlet);
        hydra_rack_temperature_alert(hdev, &env_data);
    }

    if (env_data.rack_power_total > env_data.rack_power_available * 0.9) {
        dev_warn(&hdev->pdev->dev, "High power utilization: %.1f/%.1f kW\n",
                env_data.rack_power_total, env_data.rack_power_available);
        hydra_rack_power_alert(hdev, &env_data);
    }

    // Store environmental data
    hydra_store_environmental(hdev, &env_data);

reschedule:
    // Schedule next monitoring (every 30 seconds)
    schedule_delayed_work(&hdev->rack_monitor_work, 30 * HZ);
}
```

## Hot-Swap and Serviceability

### Hot-Swap Implementation
```c
struct hydra_hotswap_config {
    bool hotswap_supported;    // Hot-swap capability
    int power_on_delay_ms;     // Delay before powering on (ms)
    int power_off_delay_ms;    // Delay before powering off (ms)
    int insertion_detection;   // Insertion detection method
    int extraction_detection;  // Extraction detection method
};

static int hydra_hotswap_enable(struct hydra_dev *hdev)
{
    struct hydra_hotswap_config *hotswap = &hdev->hotswap;
    int err;

    if (!hotswap->hotswap_supported) {
        dev_info(&hdev->pdev->dev, "Hot-swap not supported\n");
        return 0;
    }

    // Enable hot-swap detection
    err = hydra_enable_hotswap_detection(hdev);
    if (err) {
        dev_err(&hdev->pdev->dev, "Hot-swap detection enable failed: %d\n", err);
        return err;
    }

    // Register hot-swap handlers
    err = hydra_register_hotswap_handlers(hdev,
                                        hydra_hotswap_insertion_handler,
                                        hydra_hotswap_extraction_handler);
    if (err) {
        dev_err(&hdev->pdev->dev, "Hot-swap handler registration failed: %d\n", err);
        return err;
    }

    dev_info(&hdev->pdev->dev, "Hot-swap functionality enabled\n");
    return 0;
}

static void hydra_hotswap_insertion_handler(struct hydra_dev *hdev)
{
    int err;

    dev_info(&hdev->pdev->dev, "Card insertion detected\n");

    // Wait for stabilization
    msleep(hdev->hotswap.power_on_delay_ms);

    // Power on card
    err = hydra_power_on_sequence(hdev);
    if (err) {
        dev_err(&hdev->pdev->dev, "Power-on sequence failed: %d\n", err);
        return;
    }

    // Initialize card
    err = hydra_card_init(hdev);
    if (err) {
        dev_err(&hdev->pdev->dev, "Card initialization failed: %d\n", err);
        hydra_power_off_sequence(hdev);
        return;
    }

    // Notify system
    hydra_notify_insertion(hdev);

    dev_info(&hdev->pdev->dev, "Card successfully inserted and initialized\n");
}

static void hydra_hotswap_extraction_handler(struct hydra_dev *hdev)
{
    dev_info(&hdev->pdev->dev, "Card extraction detected\n");

    // Notify system of impending removal
    hydra_notify_extraction(hdev);

    // Graceful shutdown
    hydra_card_shutdown(hdev);

    // Power off sequence
    msleep(hdev->hotswap.power_off_delay_ms);
    hydra_power_off_sequence(hdev);

    dev_info(&hdev->pdev->dev, "Card safely removed\n");
}
```

## Testing and Validation

### Rack Integration Testing
```bash
#!/bin/bash
# rack_integration_test.sh

set -euo pipefail

# Test power management
test_power_management() {
    echo "Testing power management..."

    # Test power sequencing
    hydra_power_test --sequencing --delay=100

    # Test power monitoring
    hydra_power_test --monitor --duration=60

    # Test power limits
    hydra_power_test --limits --overcurrent --overtemp

    echo "Power management tests passed"
}

# Test thermal management
test_thermal_management() {
    echo "Testing thermal management..."

    # Test temperature monitoring
    hydra_thermal_test --monitor --zones=all

    # Test thermal throttling
    hydra_thermal_test --throttle --temp=80

    # Test fan control
    hydra_thermal_test --fans --speed=100

    echo "Thermal management tests passed"
}

# Test network connectivity
test_network_connectivity() {
    echo "Testing network connectivity..."

    # Test Ethernet ports
    for port in {0..3}; do
        hydra_network_test --port=$port --link --speed
    done

    # Test RDMA
    hydra_network_test --rdma --latency --bandwidth

    echo "Network connectivity tests passed"
}

# Test management interfaces
test_management_interfaces() {
    echo "Testing management interfaces..."

    # Test IPMI
    hydra_ipmi_test --device-id --sensors --power-control

    # Test Redfish
    hydra_redfish_test --api --systems --chassis

    echo "Management interface tests passed"
}

# Run all tests
test_power_management
test_thermal_management
test_network_connectivity
test_management_interfaces

echo "All rack integration tests passed"
```

This comprehensive server rack integration documentation provides the foundation for deploying Hydra accelerators in enterprise data center environments, ensuring proper power management, thermal control, network connectivity, and system management integration.</content>
<parameter name="filePath">/workspaces/hydra/docs/server_rack_integration.md