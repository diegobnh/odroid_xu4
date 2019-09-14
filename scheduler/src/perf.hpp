#pragma once
#include <cstdint>

//These number are specific to odroid_xu4
#define START_INDEX_LITTLE 0
#define END_INDEX_LITTLE 3
#define START_INDEX_BIG 4
#define END_INDEX_BIG 7

#define PMCS_A7_ONLY 0
#define PMCS_A15_ONLY 1

/// Software hardware counters.
struct PerfSoftwareData
{
    uint64_t cpu_migrations = -1;
    uint64_t context_switches = -1;
};

/// Hardware performance counters.
struct PerfHardwareData
{
    static const uint64_t no_value = -1;
    uint64_t pmc_1 = -1;
    uint64_t pmc_2 = -1;
    uint64_t pmc_3 = -1;
    uint64_t pmc_4 = -1;
    uint64_t pmc_5 = -1;
    uint64_t pmc_6 = -1;
    uint64_t pmc_7 = -1;
};

/// Initialises the performance counting subsystem.
extern void perf_init();

/// Shutdowns the performance counting subsystem.
extern void perf_shutdown();

/// Gets the number of processors configured on the system (even if offline).
extern int perf_nprocs();

/// Consumes the hardware performance counters regarding the specified
/// CPU index.
///
/// A consume operation obtains counters as if they were reset during
/// the previous consume operation.
extern auto perf_consume_hw(int cpu) -> PerfHardwareData;

/// Consumes the software performance counters regarding this process.
///
/// A consume operation obtains counters as if they were reset during
/// the previous consume operation.
extern auto perf_consume_sw(int cpu) -> PerfSoftwareData;


