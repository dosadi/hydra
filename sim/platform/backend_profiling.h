// SPDX-License-Identifier: BSD-3-Clause
// ============================================================================
// backend_profiling.h
// - Optional profiling/timing for backend operations
// - Enable with HYDRA_PROFILE_BACKEND=1
// ============================================================================
#pragma once

#include <chrono>
#include <climits>
#include <cstdio>
#include <cstdlib>

namespace backend_profiling {

// Check if profiling is enabled
inline bool is_enabled() {
    static int enabled = -1;
    if (enabled == -1) {
        const char* env = std::getenv("HYDRA_PROFILE_BACKEND");
        enabled = (env && env[0] != '\0' && env[0] != '0') ? 1 : 0;
    }
    return enabled == 1;
}

// Simple RAII timer
class Timer {
public:
    Timer(const char* operation, const char* backend_name)
        : operation_(operation)
        , backend_name_(backend_name)
        , enabled_(is_enabled())
    {
        if (enabled_) {
            start_ = std::chrono::high_resolution_clock::now();
        }
    }

    ~Timer() {
        if (enabled_) {
            auto end = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start_);
            std::fprintf(stderr, "[profile] %s::%s took %lld µs (%.3f ms)\n",
                        backend_name_,
                        operation_,
                        static_cast<long long>(duration.count()),
                        duration.count() / 1000.0);
        }
    }

private:
    const char* operation_;
    const char* backend_name_;
    bool enabled_;
    std::chrono::high_resolution_clock::time_point start_;
};

// Accumulating stats for repeated operations
class Stats {
public:
    Stats(const char* operation, const char* backend_name)
        : operation_(operation)
        , backend_name_(backend_name)
        , count_(0)
        , total_us_(0)
        , min_us_(LLONG_MAX)
        , max_us_(0)
        , enabled_(is_enabled())
    {}

    void record(long long microseconds) {
        if (!enabled_) return;

        ++count_;
        total_us_ += microseconds;
        if (microseconds < min_us_) min_us_ = microseconds;
        if (microseconds > max_us_) max_us_ = microseconds;

        // Print every 100 operations
        if (count_ % 100 == 0) {
            print_stats();
        }
    }

    void print_stats() const {
        if (!enabled_ || count_ == 0) return;

        long long avg_us = total_us_ / count_;
        std::fprintf(stderr,
                    "[profile] %s::%s stats (n=%lld): avg=%.3fms min=%.3fms max=%.3fms\n",
                    backend_name_,
                    operation_,
                    static_cast<long long>(count_),
                    avg_us / 1000.0,
                    min_us_ / 1000.0,
                    max_us_ / 1000.0);
    }

    ~Stats() {
        print_stats();
    }

private:
    const char* operation_;
    const char* backend_name_;
    long long count_;
    long long total_us_;
    long long min_us_;
    long long max_us_;
    bool enabled_;
};

// Scoped timer that records to stats
class ScopedTimer {
public:
    ScopedTimer(Stats& stats)
        : stats_(stats)
        , enabled_(is_enabled())
    {
        if (enabled_) {
            start_ = std::chrono::high_resolution_clock::now();
        }
    }

    ~ScopedTimer() {
        if (enabled_) {
            auto end = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start_);
            stats_.record(duration.count());
        }
    }

private:
    Stats& stats_;
    bool enabled_;
    std::chrono::high_resolution_clock::time_point start_;
};

} // namespace backend_profiling

// Convenience macros
#define BACKEND_PROFILE_FUNC(backend_name) \
    backend_profiling::Timer _timer(__func__, backend_name)

#define BACKEND_PROFILE_OP(backend_name, operation) \
    backend_profiling::Timer _timer(operation, backend_name)

#define BACKEND_PROFILE_STATS(backend_name, operation, stats_var) \
    static backend_profiling::Stats stats_var(operation, backend_name); \
    backend_profiling::ScopedTimer _scoped_timer(stats_var)
