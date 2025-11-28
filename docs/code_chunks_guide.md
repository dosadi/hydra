# Code Chunk Support and Reusable Patterns Guide

This guide provides a formal framework for creating, organizing, and utilizing reusable code chunks, templates, and boilerplate patterns in the Hydra project.

## Overview

Code chunks are self-contained, reusable code patterns that can be easily copied, pasted, and adapted for common development tasks. This guide establishes formal conventions for creating digestible, well-documented code chunks that accelerate development while maintaining code quality.

## Chunk Categories

### 1. Infrastructure Chunks

#### Build System Templates

**Makefile Template for New Modules**
```makefile
# Module: [MODULE_NAME]
# Description: [Brief description of module purpose]
# Dependencies: [List of dependencies]
# Author: [Your name]
# Created: [Date]

# Source files
SRCS := [module_name].c [module_name]_impl.c
HDRS := [module_name].h [module_name]_internal.h

# Object files
OBJS := $(SRCS:.c=.o)

# Build flags
CFLAGS += -I../include -I.
LDFLAGS += -lm

# Default target
.PHONY: all clean install

all: lib[module_name].a

lib[module_name].a: $(OBJS)
	$(AR) rcs $@ $^

%.o: %.c $(HDRS)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) lib[module_name].a

install: lib[module_name].a
	install -d $(DESTDIR)$(libdir)
	install -m 644 lib[module_name].a $(DESTDIR)$(libdir)
	install -d $(DESTDIR)$(includedir)
	install -m 644 $(HDRS) $(DESTDIR)$(includedir)

# Development targets
.PHONY: test debug

test: all
	./test_[module_name]

debug: CFLAGS += -g -DDEBUG
debug: all
```

**CMakeLists.txt Template**
```cmake
# Module: [MODULE_NAME]
# Description: [Brief description]
# Minimum CMake version required
cmake_minimum_required(VERSION 3.16)

# Project declaration
project([MODULE_NAME]
    VERSION 0.1.0
    DESCRIPTION "[Module description]"
    LANGUAGES C CXX
)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_BINARY_DIR}/include
)

# Source files
set(SOURCES
    src/[module_name].cpp
    src/[module_name]_impl.cpp
)

set(HEADERS
    include/[module_name].h
    include/[module_name]_internal.h
)

# Library target
add_library(${PROJECT_NAME} ${SOURCES} ${HEADERS})

# Include directories for consumers
target_include_directories(${PROJECT_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Dependencies
find_package(Threads REQUIRED)
target_link_libraries(${PROJECT_NAME}
    PUBLIC
        Threads::Threads
    PRIVATE
        # Private dependencies here
)

# Compiler features
target_compile_features(${PROJECT_NAME}
    PUBLIC
        cxx_std_17
)

# Installation
install(TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME}Targets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)

install(FILES ${HEADERS}
    DESTINATION include
)

# Export configuration
install(EXPORT ${PROJECT_NAME}Targets
    FILE ${PROJECT_NAME}Targets.cmake
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION lib/cmake/${PROJECT_NAME}
)
```

#### Test Framework Templates

**Unit Test Template (C++)**
```cpp
/**
 * @file test_[module_name].cpp
 * @brief Unit tests for [MODULE_NAME] module
 * @author [Your name]
 * @date [Date]
 */

#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "[module_name].h"

// Test fixture for [MODULE_NAME] tests
class [ModuleName]Test : public ::testing::Test {
protected:
    void SetUp() override {
        // Setup code that runs before each test
        [module_name]_init(&handle);
    }

    void TearDown() override {
        // Cleanup code that runs after each test
        [module_name]_cleanup(handle);
    }

    [module_name]_handle_t *handle;
};

// Basic functionality tests
TEST_F([ModuleName]Test, Initialization) {
    EXPECT_NE(handle, nullptr);
    EXPECT_EQ([module_name]_get_status(handle), [MODULE_NAME]_STATUS_OK);
}

TEST_F([ModuleName]Test, BasicOperation) {
    // Test basic functionality
    int result = [module_name]_process_data(handle, test_data, sizeof(test_data));
    EXPECT_EQ(result, [MODULE_NAME]_SUCCESS);
    EXPECT_EQ([module_name]_get_result(handle), expected_result);
}

// Error handling tests
TEST_F([ModuleName]Test, InvalidInput) {
    int result = [module_name]_process_data(handle, nullptr, 0);
    EXPECT_EQ(result, [MODULE_NAME]_ERROR_INVALID_INPUT);
}

TEST_F([ModuleName]Test, ResourceExhaustion) {
    // Test behavior under resource constraints
    // This might require mocking or special test setup
}

// Performance tests
TEST_F([ModuleName]Test, PerformanceBaseline) {
    auto start = std::chrono::high_resolution_clock::now();

    for (int i = 0; i < 1000; ++i) {
        [module_name]_process_data(handle, test_data, sizeof(test_data));
    }

    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

    EXPECT_LT(duration.count(), 100); // Should complete within 100ms
}

// Mock objects for testing
class Mock[ModuleName]Callback {
public:
    MOCK_METHOD(void, onDataProcessed, (const uint8_t*, size_t), ());
    MOCK_METHOD(void, onError, (int), ());
};

TEST_F([ModuleName]Test, CallbackInvocation) {
    Mock[ModuleName]Callback mock_callback;

    EXPECT_CALL(mock_callback, onDataProcessed(testing::_, sizeof(test_data)))
        .Times(1);

    [module_name]_set_callback(handle, [](const uint8_t* data, size_t size, void* user_data) {
        auto* mock = static_cast<Mock[ModuleName]Callback*>(user_data);
        mock->onDataProcessed(data, size);
    }, &mock_callback);

    [module_name]_process_data(handle, test_data, sizeof(test_data));
}
```

### 2. Algorithm Implementation Chunks

#### Data Structure Templates

**Ring Buffer Implementation**
```c
/**
 * @file ring_buffer.h
 * @brief Thread-safe ring buffer implementation
 * @author [Your name]
 * @date [Date]
 */

#ifndef RING_BUFFER_H
#define RING_BUFFER_H

#include <stdint.h>
#include <stdbool.h>
#include <pthread.h>

typedef struct {
    uint8_t *buffer;        // Data buffer
    size_t size;           // Total buffer size
    size_t read_pos;       // Read position
    size_t write_pos;      // Write position
    size_t count;          // Number of elements in buffer
    pthread_mutex_t mutex; // Thread safety
    pthread_cond_t not_empty; // Condition for readers
    pthread_cond_t not_full;  // Condition for writers
} ring_buffer_t;

/**
 * Initialize ring buffer
 * @param rb Ring buffer instance
 * @param buffer Pre-allocated buffer
 * @param size Buffer size in bytes
 * @return 0 on success, negative on error
 */
int ring_buffer_init(ring_buffer_t *rb, uint8_t *buffer, size_t size);

/**
 * Cleanup ring buffer
 * @param rb Ring buffer instance
 */
void ring_buffer_destroy(ring_buffer_t *rb);

/**
 * Write data to ring buffer (blocking)
 * @param rb Ring buffer instance
 * @param data Data to write
 * @param size Size of data
 * @return Number of bytes written, negative on error
 */
ssize_t ring_buffer_write(ring_buffer_t *rb, const uint8_t *data, size_t size);

/**
 * Read data from ring buffer (blocking)
 * @param rb Ring buffer instance
 * @param data Buffer to read into
 * @param size Maximum size to read
 * @return Number of bytes read, negative on error
 */
ssize_t ring_buffer_read(ring_buffer_t *rb, uint8_t *data, size_t size);

/**
 * Get number of bytes available for reading
 * @param rb Ring buffer instance
 * @return Number of bytes available
 */
size_t ring_buffer_available(ring_buffer_t *rb);

/**
 * Check if ring buffer is empty
 * @param rb Ring buffer instance
 * @return true if empty
 */
bool ring_buffer_empty(ring_buffer_t *rb);

/**
 * Check if ring buffer is full
 * @param rb Ring buffer instance
 * @return true if full
 */
bool ring_buffer_full(ring_buffer_t *rb);

#endif /* RING_BUFFER_H */
```

```c
/**
 * @file ring_buffer.c
 * @brief Ring buffer implementation
 */

#include "ring_buffer.h"
#include <string.h>
#include <errno.h>
#include <assert.h>

int ring_buffer_init(ring_buffer_t *rb, uint8_t *buffer, size_t size) {
    if (!rb || !buffer || size == 0) {
        return -EINVAL;
    }

    rb->buffer = buffer;
    rb->size = size;
    rb->read_pos = 0;
    rb->write_pos = 0;
    rb->count = 0;

    if (pthread_mutex_init(&rb->mutex, NULL) != 0) {
        return -errno;
    }

    if (pthread_cond_init(&rb->not_empty, NULL) != 0) {
        pthread_mutex_destroy(&rb->mutex);
        return -errno;
    }

    if (pthread_cond_init(&rb->not_full, NULL) != 0) {
        pthread_cond_destroy(&rb->not_empty);
        pthread_mutex_destroy(&rb->mutex);
        return -errno;
    }

    return 0;
}

void ring_buffer_destroy(ring_buffer_t *rb) {
    if (!rb) return;

    pthread_cond_destroy(&rb->not_full);
    pthread_cond_destroy(&rb->not_empty);
    pthread_mutex_destroy(&rb->mutex);
}

ssize_t ring_buffer_write(ring_buffer_t *rb, const uint8_t *data, size_t size) {
    if (!rb || !data) {
        return -EINVAL;
    }

    pthread_mutex_lock(&rb->mutex);

    // Wait for space if buffer is full
    while (rb->count == rb->size) {
        pthread_cond_wait(&rb->not_full, &rb->mutex);
    }

    size_t bytes_written = 0;
    size_t remaining = size;

    while (remaining > 0 && rb->count < rb->size) {
        size_t chunk_size = remaining;
        size_t space_to_end = rb->size - rb->write_pos;

        if (chunk_size > space_to_end) {
            chunk_size = space_to_end;
        }

        if (chunk_size > rb->size - rb->count) {
            chunk_size = rb->size - rb->count;
        }

        memcpy(rb->buffer + rb->write_pos, data + bytes_written, chunk_size);

        rb->write_pos = (rb->write_pos + chunk_size) % rb->size;
        rb->count += chunk_size;
        bytes_written += chunk_size;
        remaining -= chunk_size;
    }

    pthread_cond_signal(&rb->not_empty);
    pthread_mutex_unlock(&rb->mutex);

    return bytes_written;
}

ssize_t ring_buffer_read(ring_buffer_t *rb, uint8_t *data, size_t size) {
    if (!rb || !data) {
        return -EINVAL;
    }

    pthread_mutex_lock(&rb->mutex);

    // Wait for data if buffer is empty
    while (rb->count == 0) {
        pthread_cond_wait(&rb->not_empty, &rb->mutex);
    }

    size_t bytes_read = 0;
    size_t remaining = size;

    while (remaining > 0 && rb->count > 0) {
        size_t chunk_size = remaining;
        size_t data_to_end = rb->size - rb->read_pos;

        if (chunk_size > data_to_end) {
            chunk_size = data_to_end;
        }

        if (chunk_size > rb->count) {
            chunk_size = rb->count;
        }

        memcpy(data + bytes_read, rb->buffer + rb->read_pos, chunk_size);

        rb->read_pos = (rb->read_pos + chunk_size) % rb->size;
        rb->count -= chunk_size;
        bytes_read += chunk_size;
        remaining -= chunk_size;
    }

    pthread_cond_signal(&rb->not_full);
    pthread_mutex_unlock(&rb->mutex);

    return bytes_read;
}

size_t ring_buffer_available(ring_buffer_t *rb) {
    if (!rb) return 0;

    pthread_mutex_lock(&rb->mutex);
    size_t available = rb->count;
    pthread_mutex_unlock(&rb->mutex);

    return available;
}

bool ring_buffer_empty(ring_buffer_t *rb) {
    if (!rb) return true;

    pthread_mutex_lock(&rb->mutex);
    bool empty = (rb->count == 0);
    pthread_mutex_unlock(&rb->mutex);

    return empty;
}

bool ring_buffer_full(ring_buffer_t *rb) {
    if (!rb) return true;

    pthread_mutex_lock(&rb->mutex);
    bool full = (rb->count == rb->size);
    pthread_mutex_unlock(&rb->mutex);

    return full;
}
```

#### State Machine Template
```c
/**
 * @file state_machine.h
 * @brief Generic state machine implementation
 * @author [Your name]
 * @date [Date]
 */

#ifndef STATE_MACHINE_H
#define STATE_MACHINE_H

#include <stdint.h>
#include <stdbool.h>

// Forward declarations
typedef struct state_machine_t state_machine_t;
typedef struct state_t state_t;

// State handler function type
typedef void (*state_handler_t)(state_machine_t *sm, void *event_data);

// State transition function type
typedef bool (*transition_guard_t)(state_machine_t *sm, void *event_data);

// State definition
struct state_t {
    const char *name;                    // State name for debugging
    state_handler_t entry_handler;       // Called when entering state
    state_handler_t exit_handler;        // Called when exiting state
    state_handler_t event_handler;       // Called for events in this state
};

// State machine instance
struct state_machine_t {
    const state_t *current_state;        // Current state
    const state_t *previous_state;       // Previous state (for undo)
    void *user_data;                     // User context data
    uint32_t event_count;                // Event counter for debugging

    // Transition table (can be customized per state machine)
    struct {
        const state_t *from_state;
        const state_t *to_state;
        uint32_t event_type;
        transition_guard_t guard;        // Optional guard condition
    } *transitions;

    uint32_t num_transitions;
};

/**
 * Initialize state machine
 * @param sm State machine instance
 * @param initial_state Initial state
 * @param user_data User context data
 * @param transitions Transition table
 * @param num_transitions Number of transitions
 */
void state_machine_init(state_machine_t *sm,
                       const state_t *initial_state,
                       void *user_data,
                       void *transitions,
                       uint32_t num_transitions);

/**
 * Process event
 * @param sm State machine instance
 * @param event_type Event type identifier
 * @param event_data Event-specific data
 * @return true if transition occurred
 */
bool state_machine_process_event(state_machine_t *sm,
                                uint32_t event_type,
                                void *event_data);

/**
 * Get current state name
 * @param sm State machine instance
 * @return State name string
 */
const char *state_machine_get_state_name(const state_machine_t *sm);

/**
 * Force state transition (for initialization/error recovery)
 * @param sm State machine instance
 * @param new_state New state
 */
void state_machine_set_state(state_machine_t *sm, const state_t *new_state);

#endif /* STATE_MACHINE_H */
```

### 3. Protocol Implementation Chunks

#### Packet Parser Template
```c
/**
 * @file packet_parser.h
 * @brief Generic packet parser with validation
 * @author [Your name]
 * @date [Date]
 */

#ifndef PACKET_PARSER_H
#define PACKET_PARSER_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// Packet parser result codes
typedef enum {
    PACKET_PARSER_OK = 0,
    PACKET_PARSER_INCOMPLETE,      // Need more data
    PACKET_PARSER_INVALID_HEADER,  // Invalid header
    PACKET_PARSER_INVALID_PAYLOAD, // Invalid payload
    PACKET_PARSER_CHECKSUM_ERROR,  // Checksum mismatch
    PACKET_PARSER_BUFFER_OVERFLOW, // Buffer too small
    PACKET_PARSER_TIMEOUT,         // Parsing timeout
} packet_parser_result_t;

// Packet parser configuration
typedef struct {
    uint32_t max_packet_size;      // Maximum packet size
    uint32_t timeout_ms;           // Parsing timeout
    bool strict_mode;              // Strict validation mode
    uint32_t max_retries;          // Maximum parse retries
} packet_parser_config_t;

// Packet parser instance
typedef struct {
    packet_parser_config_t config;
    uint8_t *buffer;                // Working buffer
    size_t buffer_size;             // Buffer size
    size_t data_length;             // Current data length
    uint32_t state;                 // Parser state
    uint32_t last_activity;         // Timestamp of last activity
    uint32_t retry_count;           // Current retry count

    // Statistics
    uint32_t packets_parsed;
    uint32_t packets_dropped;
    uint32_t checksum_errors;
    uint32_t timeout_errors;
} packet_parser_t;

/**
 * Initialize packet parser
 * @param parser Parser instance
 * @param config Parser configuration
 * @param buffer Working buffer
 * @param buffer_size Buffer size
 * @return 0 on success
 */
int packet_parser_init(packet_parser_t *parser,
                      const packet_parser_config_t *config,
                      uint8_t *buffer,
                      size_t buffer_size);

/**
 * Reset parser state
 * @param parser Parser instance
 */
void packet_parser_reset(packet_parser_t *parser);

/**
 * Feed data to parser
 * @param parser Parser instance
 * @param data Input data
 * @param length Data length
 * @param timestamp Current timestamp
 * @return Parser result
 */
packet_parser_result_t packet_parser_feed(packet_parser_t *parser,
                                        const uint8_t *data,
                                        size_t length,
                                        uint32_t timestamp);

/**
 * Check if parser has complete packet
 * @param parser Parser instance
 * @return true if packet is complete
 */
bool packet_parser_has_packet(const packet_parser_t *parser);

/**
 * Extract parsed packet
 * @param parser Parser instance
 * @param packet_data Output buffer for packet data
 * @param packet_size Size of output buffer
 * @return Packet size on success, negative on error
 */
ssize_t packet_parser_get_packet(packet_parser_t *parser,
                               uint8_t *packet_data,
                               size_t packet_size);

/**
 * Get parser statistics
 * @param parser Parser instance
 * @param stats Output statistics structure
 */
void packet_parser_get_stats(const packet_parser_t *parser,
                           struct packet_parser_stats *stats);

#endif /* PACKET_PARSER_H */
```

#### Command Dispatcher Template
```c
/**
 * @file command_dispatcher.h
 * @brief Command dispatcher with validation and logging
 * @author [Your name]
 * @date [Date]
 */

#ifndef COMMAND_DISPATCHER_H
#define COMMAND_DISPATCHER_H

#include <stdint.h>
#include <stdbool.h>

// Command result codes
typedef enum {
    CMD_SUCCESS = 0,
    CMD_INVALID_COMMAND,
    CMD_INVALID_PARAMETERS,
    CMD_PERMISSION_DENIED,
    CMD_EXECUTION_FAILED,
    CMD_TIMEOUT,
    CMD_QUEUE_FULL,
} command_result_t;

// Command handler function type
typedef command_result_t (*command_handler_t)(void *context,
                                            uint32_t command_id,
                                            const uint8_t *params,
                                            size_t param_length,
                                            uint8_t *response,
                                            size_t *response_length);

// Command definition
typedef struct {
    uint32_t command_id;            // Unique command identifier
    const char *name;               // Command name for logging
    command_handler_t handler;      // Command handler function
    uint32_t min_param_length;      // Minimum parameter length
    uint32_t max_param_length;      // Maximum parameter length
    uint32_t max_response_length;   // Maximum response length
    bool requires_auth;             // Authentication required
    uint32_t timeout_ms;            // Command timeout
} command_definition_t;

// Command dispatcher configuration
typedef struct {
    uint32_t max_concurrent_commands; // Maximum concurrent commands
    uint32_t command_timeout_ms;      // Default command timeout
    uint32_t max_queue_depth;         // Maximum command queue depth
    bool enable_logging;              // Enable command logging
    bool strict_validation;           // Strict parameter validation
} command_dispatcher_config_t;

// Command dispatcher instance
typedef struct command_dispatcher_t command_dispatcher_t;

/**
 * Create command dispatcher
 * @param config Dispatcher configuration
 * @param commands Array of command definitions
 * @param num_commands Number of commands
 * @return Dispatcher instance or NULL on error
 */
command_dispatcher_t *command_dispatcher_create(
    const command_dispatcher_config_t *config,
    const command_definition_t *commands,
    uint32_t num_commands);

/**
 * Destroy command dispatcher
 * @param dispatcher Dispatcher instance
 */
void command_dispatcher_destroy(command_dispatcher_t *dispatcher);

/**
 * Dispatch command (asynchronous)
 * @param dispatcher Dispatcher instance
 * @param command_id Command identifier
 * @param params Command parameters
 * @param param_length Parameter length
 * @param context User context
 * @param callback Completion callback
 * @return 0 on success, negative on error
 */
int command_dispatcher_dispatch(command_dispatcher_t *dispatcher,
                              uint32_t command_id,
                              const uint8_t *params,
                              size_t param_length,
                              void *context,
                              void (*callback)(void *context, command_result_t result,
                                             const uint8_t *response, size_t response_length));

/**
 * Dispatch command (synchronous)
 * @param dispatcher Dispatcher instance
 * @param command_id Command identifier
 * @param params Command parameters
 * @param param_length Parameter length
 * @param response Response buffer
 * @param response_capacity Response buffer capacity
 * @param response_length Actual response length
 * @param timeout_ms Timeout in milliseconds
 * @return Command result
 */
command_result_t command_dispatcher_dispatch_sync(
    command_dispatcher_t *dispatcher,
    uint32_t command_id,
    const uint8_t *params,
    size_t param_length,
    uint8_t *response,
    size_t response_capacity,
    size_t *response_length,
    uint32_t timeout_ms);

/**
 * Cancel pending command
 * @param dispatcher Dispatcher instance
 * @param command_id Command identifier to cancel
 * @return true if command was cancelled
 */
bool command_dispatcher_cancel(command_dispatcher_t *dispatcher,
                             uint32_t command_id);

/**
 * Get dispatcher statistics
 * @param dispatcher Dispatcher instance
 * @param stats Statistics output
 */
void command_dispatcher_get_stats(const command_dispatcher_t *dispatcher,
                                struct command_dispatcher_stats *stats);

#endif /* COMMAND_DISPATCHER_H */
```

### 4. Error Handling and Logging Chunks

#### Error Context Template
```c
/**
 * @file error_context.h
 * @brief Structured error handling with context
 * @author [Your name]
 * @date [Date]
 */

#ifndef ERROR_CONTEXT_H
#define ERROR_CONTEXT_H

#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>

// Error severity levels
typedef enum {
    ERROR_SEVERITY_DEBUG = 0,
    ERROR_SEVERITY_INFO,
    ERROR_SEVERITY_WARNING,
    ERROR_SEVERITY_ERROR,
    ERROR_SEVERITY_CRITICAL,
    ERROR_SEVERITY_FATAL
} error_severity_t;

// Error categories
typedef enum {
    ERROR_CATEGORY_SYSTEM = 0,      // System-level errors
    ERROR_CATEGORY_NETWORK,         // Network errors
    ERROR_CATEGORY_PROTOCOL,        // Protocol errors
    ERROR_CATEGORY_SECURITY,        // Security errors
    ERROR_CATEGORY_APPLICATION,     // Application errors
    ERROR_CATEGORY_USER             // User input errors
} error_category_t;

// Error context structure
typedef struct {
    uint32_t error_code;            // Numeric error code
    error_severity_t severity;      // Error severity
    error_category_t category;      // Error category
    const char *module;             // Module where error occurred
    const char *function;           // Function where error occurred
    uint32_t line;                  // Line number
    const char *file;               // Source file
    char message[256];              // Error message
    uint32_t timestamp;             // Error timestamp
    void *context_data;             // Additional context data
    size_t context_size;            // Size of context data
} error_context_t;

// Error handler function type
typedef void (*error_handler_t)(const error_context_t *error, void *user_data);

/**
 * Initialize error handling system
 * @param handler Error handler callback
 * @param user_data User data for handler
 */
void error_init(error_handler_t handler, void *user_data);

/**
 * Report error with context
 * @param error_code Numeric error code
 * @param severity Error severity
 * @param category Error category
 * @param module Module name
 * @param function Function name
 * @param line Line number
 * @param file Source file
 * @param format Error message format
 * @param ... Format arguments
 */
void error_report(uint32_t error_code,
                 error_severity_t severity,
                 error_category_t category,
                 const char *module,
                 const char *function,
                 uint32_t line,
                 const char *file,
                 const char *format, ...);

/**
 * Report error with va_list
 * @param error_code Numeric error code
 * @param severity Error severity
 * @param category Error category
 * @param module Module name
 * @param function Function name
 * @param line Line number
 * @param file Source file
 * @param format Error message format
 * @param args Format arguments
 */
void error_report_v(uint32_t error_code,
                   error_severity_t severity,
                   error_category_t category,
                   const char *module,
                   const char *function,
                   uint32_t line,
                   const char *file,
                   const char *format,
                   va_list args);

/**
 * Set error context data
 * @param data Context data
 * @param size Data size
 */
void error_set_context(const void *data, size_t size);

/**
 * Get last error context
 * @return Last error context
 */
const error_context_t *error_get_last(void);

/**
 * Clear error state
 */
void error_clear(void);

/**
 * Check if error state is set
 * @return true if error occurred
 */
bool error_occurred(void);

// Convenience macros
#define ERROR_REPORT(code, severity, category, format, ...) \
    error_report(code, severity, category, \
                __FILE__, __func__, __LINE__, \
                MODULE_NAME, format, ##__VA_ARGS__)

#define ERROR_SYSTEM(code, format, ...) \
    ERROR_REPORT(code, ERROR_SEVERITY_ERROR, ERROR_CATEGORY_SYSTEM, format, ##__VA_ARGS__)

#define ERROR_NETWORK(code, format, ...) \
    ERROR_REPORT(code, ERROR_SEVERITY_ERROR, ERROR_CATEGORY_NETWORK, format, ##__VA_ARGS__)

#define ERROR_SECURITY(code, format, ...) \
    ERROR_REPORT(code, ERROR_SEVERITY_ERROR, ERROR_CATEGORY_SECURITY, format, ##__VA_ARGS__)

#endif /* ERROR_CONTEXT_H */
```

## Chunk Organization and Management

### Directory Structure
```
chunks/
├── infrastructure/
│   ├── build_system/
│   │   ├── makefile_template.mk
│   │   ├── cmake_template.cmake
│   │   └── meson_template.build
│   ├── testing/
│   │   ├── unit_test_template.cpp
│   │   ├── integration_test_template.py
│   │   └── benchmark_template.c
│   └── documentation/
│       ├── readme_template.md
│       └── api_docs_template.md
├── algorithms/
│   ├── data_structures/
│   │   ├── ring_buffer.h
│   │   ├── ring_buffer.c
│   │   ├── hash_table.h
│   │   └── hash_table.c
│   ├── state_machines/
│   │   ├── state_machine.h
│   │   ├── state_machine.c
│   │   └── state_machine_examples/
│   └── sorting/
│       ├── quicksort.h
│       └── mergesort.c
├── protocols/
│   ├── parsers/
│   │   ├── packet_parser.h
│   │   ├── packet_parser.c
│   │   └── protocol_examples/
│   ├── dispatchers/
│   │   ├── command_dispatcher.h
│   │   └── command_dispatcher.c
│   └── serializers/
│       ├── json_serializer.h
│       └── binary_serializer.c
├── error_handling/
│   ├── error_context.h
│   ├── error_context.c
│   ├── logging_system.h
│   └── logging_system.c
└── utilities/
    ├── memory/
    │   ├── pool_allocator.h
    │   └── pool_allocator.c
    ├── timing/
    │   ├── timer.h
    │   └── profiler.c
    └── platform/
        ├── thread_wrapper.h
        └── thread_wrapper.c
```

### Chunk Metadata Format
```yaml
# chunk_metadata.yaml
chunk:
  name: "ring_buffer"
  version: "1.0.0"
  author: "[Your name]"
  description: "Thread-safe ring buffer implementation"
  category: "data_structures"
  language: "c"
  license: "MIT"
  dependencies: []
  tags:
    - "data-structure"
    - "thread-safe"
    - "circular-buffer"
  files:
    - "ring_buffer.h"
    - "ring_buffer.c"
  test_files:
    - "test_ring_buffer.c"
  example_files:
    - "ring_buffer_example.c"
  documentation:
    - "README.md"
    - "API_REFERENCE.md"
  created: "2025-11-28"
  last_modified: "2025-11-28"
  compatibility:
    compilers:
      - "gcc >= 7.0"
      - "clang >= 6.0"
    platforms:
      - "linux"
      - "windows"
      - "macos"
    architectures:
      - "x86_64"
      - "arm64"
```

### Chunk Validation Script
```bash
#!/bin/bash
# validate_chunk.sh - Validate code chunk completeness and correctness

set -e

CHUNK_DIR="$1"
CHUNK_NAME="$(basename "$CHUNK_DIR")"

echo "Validating chunk: $CHUNK_NAME"

# Check required files exist
required_files=("chunk_metadata.yaml" "README.md")
for file in "${required_files[@]}"; do
    if [[ ! -f "$CHUNK_DIR/$file" ]]; then
        echo "ERROR: Missing required file: $file"
        exit 1
    fi
done

# Validate metadata
if ! yamllint "$CHUNK_DIR/chunk_metadata.yaml"; then
    echo "ERROR: Invalid YAML in metadata"
    exit 1
fi

# Check code compiles (if applicable)
if [[ -f "$CHUNK_DIR/Makefile" ]]; then
    echo "Testing compilation..."
    cd "$CHUNK_DIR"
    make clean >/dev/null 2>&1
    if ! make >/dev/null 2>&1; then
        echo "ERROR: Code does not compile"
        exit 1
    fi
    make clean >/dev/null 2>&1
fi

# Run tests (if available)
if [[ -f "$CHUNK_DIR/test.sh" ]]; then
    echo "Running tests..."
    cd "$CHUNK_DIR"
    if ! ./test.sh; then
        echo "ERROR: Tests failed"
        exit 1
    fi
fi

# Check documentation
if ! markdownlint "$CHUNK_DIR/README.md"; then
    echo "WARNING: Documentation formatting issues"
fi

echo "Chunk validation passed!"
```

## Usage Guidelines

### When to Create a Chunk
- **Reusable Pattern**: Code that solves a common problem
- **Complex Logic**: Non-trivial algorithms or data structures
- **Protocol Implementation**: Standard protocol handling
- **Infrastructure**: Build systems, testing frameworks
- **Cross-Project Value**: Useful beyond current project

### Chunk Creation Process
1. **Identify Need**: Recognize reusable pattern
2. **Design Interface**: Clean, minimal API
3. **Implement Core**: Focus on correctness and efficiency
4. **Add Documentation**: Comprehensive README and examples
5. **Write Tests**: Unit tests and integration tests
6. **Validate**: Run validation script
7. **Publish**: Add to chunk repository

### Using Chunks in Projects
```makefile
# Include chunk in build system
CHUNK_DIR := ../chunks
INCLUDE_DIRS += $(CHUNK_DIR)/data_structures
SOURCES += $(CHUNK_DIR)/data_structures/ring_buffer.c

# Or as git submodule
git submodule add https://github.com/your-org/chunks.git chunks
```

### Adapting Chunks
```c
// Original chunk usage
ring_buffer_t rb;
ring_buffer_init(&rb, buffer, sizeof(buffer));

// Adapted for specific use case
typedef struct {
    ring_buffer_t base;
    uint32_t magic_number;  // Additional field
    custom_validator_t validator;  // Custom validation
} custom_ring_buffer_t;

// Wrapper functions
int custom_ring_buffer_init(custom_ring_buffer_t *crb, uint8_t *buffer, size_t size) {
    int ret = ring_buffer_init(&crb->base, buffer, size);
    if (ret == 0) {
        crb->magic_number = CUSTOM_MAGIC;
        crb->validator = custom_validator;
    }
    return ret;
}
```

## Quality Assurance

### Code Standards
- **Documentation**: Every public function documented
- **Error Handling**: Comprehensive error checking
- **Thread Safety**: Clear thread safety guarantees
- **Performance**: Complexity analysis provided
- **Testing**: 80%+ code coverage minimum
- **Portability**: Works across target platforms

### Review Checklist
- [ ] Code compiles without warnings
- [ ] All tests pass
- [ ] Documentation is complete
- [ ] No memory leaks (valgrind clean)
- [ ] Thread safety verified
- [ ] Performance benchmarks included
- [ ] Cross-platform compatibility tested
- [ ] License compatibility verified

### Maintenance Guidelines
- **Versioning**: Semantic versioning (MAJOR.MINOR.PATCH)
- **Deprecation**: Clear deprecation notices
- **Breaking Changes**: Major version bumps
- **Security**: Regular security audits
- **Updates**: Keep dependencies current

## Integration with Development Workflow

### IDE Integration
```json
// VS Code snippets for chunk insertion
{
    "Ring Buffer Declaration": {
        "prefix": "ring_buffer_decl",
        "body": [
            "ring_buffer_t ${1:rb};",
            "uint8_t ${2:buffer}[${3:1024}];",
            "",
            "if (ring_buffer_init(&${1:rb}, ${2:buffer}, sizeof(${2:buffer})) != 0) {",
            "    // Handle initialization error",
            "}"
        ],
        "description": "Declare and initialize a ring buffer"
    }
}
```

### CI/CD Integration
```yaml
# .github/workflows/chunk-validation.yml
name: Chunk Validation
on:
  push:
    paths:
      - 'chunks/**'
  pull_request:
    paths:
      - 'chunks/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Validate chunks
      run: |
        find chunks -name "validate_chunk.sh" -exec bash {} \;
```

### Documentation Integration
```markdown
<!-- Include chunk in documentation -->
## Using Ring Buffer

```c
#include "ring_buffer.h"

// See [Ring Buffer Chunk](../../chunks/data_structures/ring_buffer/)
ring_buffer_t rb;
uint8_t buffer[1024];

ring_buffer_init(&rb, buffer, sizeof(buffer));
// ... use ring buffer
```

For complete API documentation, see the [Ring Buffer Reference](../../chunks/data_structures/ring_buffer/README.md).
```

## Future Enhancements

### Advanced Features
- **Code Generation**: Automatic chunk adaptation
- **Dependency Management**: Automatic dependency resolution
- **Version Constraints**: Semantic version compatibility
- **Performance Profiling**: Built-in benchmarking
- **Code Analysis**: Static analysis integration

### Tooling Improvements
- **Chunk Browser**: Web interface for exploring chunks
- **Auto-Update**: Automatic chunk updates
- **Integration Tests**: Cross-chunk compatibility testing
- **Performance Database**: Performance regression tracking

### Community Features
- **Chunk Registry**: Centralized chunk repository
- **Rating System**: Community feedback integration
- **Forking**: Community chunk variations
- **Collaboration**: Multi-author chunk development

---

**Document Version:** 1.0
**Last Updated:** 2025-11-28
**Status:** Framework for code chunk management
**Next Steps:** Implement chunk validation tooling and populate initial chunk library