// SPDX-License-Identifier: BSD-3-Clause
// ============================================================================
// backend_logging.h
// - Centralized logging control for backend operations
// - Supports quiet mode for CI/batch operations
// ============================================================================
#pragma once

#include <cstdio>
#include <cstdlib>

namespace backend_logging {

// Logging levels
enum class Level {
    ERROR,   // Always shown
    WARN,    // Shown unless quiet
    INFO,    // Shown unless quiet
    DEBUG    // Only shown if verbose
};

// Check if quiet mode is enabled
inline bool is_quiet() {
    static int quiet = -1;
    if (quiet == -1) {
        const char* env = std::getenv("HYDRA_QUIET");
        quiet = (env && env[0] != '\0' && env[0] != '0') ? 1 : 0;
    }
    return quiet == 1;
}

// Check if verbose mode is enabled
inline bool is_verbose() {
    static int verbose = -1;
    if (verbose == -1) {
        const char* env = std::getenv("HYDRA_VERBOSE");
        verbose = (env && env[0] != '\0' && env[0] != '0') ? 1 : 0;
    }
    return verbose == 1;
}

// Check if a message should be logged
inline bool should_log(Level level) {
    if (level == Level::ERROR) {
        return true;  // Always show errors
    }
    if (is_quiet()) {
        return false;  // Quiet mode suppresses warnings and info
    }
    if (level == Level::DEBUG) {
        return is_verbose();  // Debug only in verbose mode
    }
    return true;  // Show warnings and info by default
}

// Helper macros for backend logging
#define BACKEND_LOG_ERROR(fmt, ...) \
    std::fprintf(stderr, "[%s] ERROR: " fmt "\n", __VA_ARGS__)

#define BACKEND_LOG_WARN(backend, fmt, ...) \
    do { \
        if (backend_logging::should_log(backend_logging::Level::WARN)) { \
            std::fprintf(stderr, "[%s] " fmt "\n", backend, __VA_ARGS__); \
        } \
    } while(0)

#define BACKEND_LOG_INFO(backend, fmt, ...) \
    do { \
        if (backend_logging::should_log(backend_logging::Level::INFO)) { \
            std::fprintf(stderr, "[%s] " fmt "\n", backend, __VA_ARGS__); \
        } \
    } while(0)

#define BACKEND_LOG_DEBUG(backend, fmt, ...) \
    do { \
        if (backend_logging::should_log(backend_logging::Level::DEBUG)) { \
            std::fprintf(stderr, "[%s] DEBUG: " fmt "\n", backend, __VA_ARGS__); \
        } \
    } while(0)

// Simple versions for messages without format args
#define BACKEND_LOG_ERROR_STR(backend, msg) \
    std::fprintf(stderr, "[%s] ERROR: %s\n", backend, msg)

#define BACKEND_LOG_WARN_STR(backend, msg) \
    do { \
        if (backend_logging::should_log(backend_logging::Level::WARN)) { \
            std::fprintf(stderr, "[%s] %s\n", backend, msg); \
        } \
    } while(0)

#define BACKEND_LOG_INFO_STR(backend, msg) \
    do { \
        if (backend_logging::should_log(backend_logging::Level::INFO)) { \
            std::fprintf(stderr, "[%s] %s\n", backend, msg); \
        } \
    } while(0)

#define BACKEND_LOG_DEBUG_STR(backend, msg) \
    do { \
        if (backend_logging::should_log(backend_logging::Level::DEBUG)) { \
            std::fprintf(stderr, "[%s] DEBUG: %s\n", backend, msg); \
        } \
    } while(0)

} // namespace backend_logging
