#include "perf.hpp"
#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <unistd.h>
#include <asm/unistd.h>
#include <sys/ioctl.h>
#include <sys/sysinfo.h>
#include <linux/perf_event.h>


/// Maximum events that can be recorded simultaneously.
///
/// The Cortex A7 is a limiting factor here because it contains
/// only four performance counting registers.
constexpr int MAX_EVENTS_PER_GROUP = 7;

/// Maximum number of processor cores we are going to use.
constexpr int MAX_PROCESSORS = 8;

/// Number of software counters to collect.
constexpr int NUM_SOFTWARE_COUNTERS = 2;

struct PerfEvent
{
    int fd;
    uint64_t id;
    uint64_t prev_value;
};

static PerfEvent perf_cpu[MAX_PROCESSORS][MAX_EVENTS_PER_GROUP];
static PerfEvent perf_sw[MAX_PROCESSORS][NUM_SOFTWARE_COUNTERS];
static int num_processors;


void perf_init_little()
{

    auto perf_event_open = [](struct perf_event_attr *hw_event, pid_t pid,
                               int cpu, int group_fd, unsigned long flags) {
        return syscall(__NR_perf_event_open, hw_event, pid, cpu,
                       group_fd, flags);
    };

    num_processors = get_nprocs_conf();
    assert(num_processors <= MAX_PROCESSORS);

    //fprintf(stderr, "scheduler: detected %d processors\n", num_processors);

    for(int cpu = START_INDEX_LITTLE; cpu <= END_INDEX_LITTLE; ++cpu)
    {
        for(int i = 0; i < MAX_EVENTS_PER_GROUP; ++i)
        {
            uint64_t config;
            int group_fd;
            struct perf_event_attr pe;
            memset(&pe, 0, sizeof(pe));

            switch(i)
            {
                case 0:
		    config = PERF_COUNT_HW_CPU_CYCLES;
		    group_fd = -1;
                    pe.type = PERF_TYPE_HARDWARE;
		    break;
                case 1:
		    config = 0x08;
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
                case 2:
		    config = 0x13;
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
		case 3:
                    config = 0x17;
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
		case 4:
                    config = 0x19;
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
                default:
		    perf_cpu[cpu][i].fd = -1;
		    perf_cpu[cpu][i].id = -1;
                    pe.type = PERF_TYPE_RAW;
		    continue;
            }

            pe.size = sizeof(pe);
            //pe.type = PERF_TYPE_RAW;
            pe.config = config;
            pe.exclude_hv = true;
            pe.exclude_kernel = true;
            pe.disabled = true;
            pe.read_format = PERF_FORMAT_ID | PERF_FORMAT_GROUP;

            const auto fd = perf_event_open(&pe, -1, cpu, group_fd, 0);
            if(fd == -1)
            {
                perror("scheduler: failed to initialise perf");
                abort();
            }

            perf_cpu[cpu][i].fd = fd;
            ioctl(fd, PERF_EVENT_IOC_ID, &perf_cpu[cpu][i].id);
            ioctl(fd, PERF_EVENT_IOC_RESET, 0);
            perf_cpu[cpu][i].prev_value = 0;
        }
    }

    

    for(int cpu = START_INDEX_LITTLE; cpu <= END_INDEX_LITTLE; ++cpu)
    {

        for(int i = 0; i < NUM_SOFTWARE_COUNTERS; ++i)
        {
                uint64_t config;
                int group_fd;

                switch(i)
                {
                        case 0:
	                    config = PERF_COUNT_SW_CPU_MIGRATIONS;
	                    group_fd = -1;
                            //group_fd = perf_sw[cpu][0].fd;
	                    break;
                        case 1:
	                    config = PERF_COUNT_SW_CONTEXT_SWITCHES;
	                    group_fd = perf_sw[cpu][0].fd;
	                    break;
                        default:
	                    perf_sw[cpu][i].fd = -1;
	                    perf_sw[cpu][i].id = -1;
	                    continue;
                }

                struct perf_event_attr pe;
                memset(&pe, 0, sizeof(pe));
                pe.size = sizeof(pe);
                pe.type = PERF_TYPE_SOFTWARE;
                pe.config = config;
                pe.exclude_hv = true;
                pe.exclude_kernel = false;
                pe.disabled = true;
                pe.read_format = PERF_FORMAT_ID | PERF_FORMAT_GROUP;

                const auto fd = perf_event_open(&pe, -1, cpu, group_fd, 0);
                if(fd == -1)
                {
                     perror("scheduler: failed to initialise perf");
                     abort();
                }

                perf_sw[cpu][i].fd = fd;
                ioctl(fd, PERF_EVENT_IOC_ID, &perf_sw[cpu][i].id);
                ioctl(fd, PERF_EVENT_IOC_RESET, 0);
                perf_sw[cpu][i].prev_value = 0;
          }
    }


    for(int cpu = START_INDEX_LITTLE; cpu <= END_INDEX_LITTLE; ++cpu)
    {
        const auto leader_fd = perf_cpu[cpu][0].fd;
        ioctl(leader_fd, PERF_EVENT_IOC_ENABLE, PERF_IOC_FLAG_GROUP);
    }

    for(int cpu = START_INDEX_LITTLE; cpu <= END_INDEX_LITTLE; ++cpu)
    {
        const auto leader_fd = perf_sw[cpu][0].fd;
        ioctl(leader_fd, PERF_EVENT_IOC_ENABLE, PERF_IOC_FLAG_GROUP);
    }
}


void perf_init_big()
{
    auto perf_event_open = [](struct perf_event_attr *hw_event, pid_t pid,
                               int cpu, int group_fd, unsigned long flags) {
        return syscall(__NR_perf_event_open, hw_event, pid, cpu,
                       group_fd, flags);
    };

    num_processors = get_nprocs_conf();
    assert(num_processors <= MAX_PROCESSORS);

    for(int cpu = START_INDEX_BIG; cpu <= END_INDEX_BIG; ++cpu)
    {
        for(int i = 0; i < MAX_EVENTS_PER_GROUP; ++i)
        {
            uint64_t config;
            int group_fd;
            struct perf_event_attr pe;
            memset(&pe, 0, sizeof(pe));


            switch(i)
            {
                case 0:
		    config = PERF_COUNT_HW_CPU_CYCLES;
		    group_fd = -1;
                    pe.type = PERF_TYPE_HARDWARE;
		    break;
                case 1:
		    config = 0x08;
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
                case 2:
		    config = 0x13;
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
		case 3:
                    config = 0x17;
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
		case 4:
                    config = 0x19;
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
                case 5:
                    config = 0x6C;
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
                    break;
                case 6:
                    config = 0x6D;
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
                    break;
                default:
		    perf_cpu[cpu][i].fd = -1;
		    perf_cpu[cpu][i].id = -1;
                    pe.type = PERF_TYPE_RAW;
		    continue;
            }

            pe.size = sizeof(pe);
            //pe.type = PERF_TYPE_RAW;
            pe.config = config;
            pe.exclude_hv = true;
            pe.exclude_kernel = true;
            pe.disabled = true;
            pe.read_format = PERF_FORMAT_ID | PERF_FORMAT_GROUP;

            const auto fd = perf_event_open(&pe, -1, cpu, group_fd, 0);
            if(fd == -1)
            {
                perror("scheduler: failed to initialise perf");
                abort();
            }

            perf_cpu[cpu][i].fd = fd;
            ioctl(fd, PERF_EVENT_IOC_ID, &perf_cpu[cpu][i].id);
            ioctl(fd, PERF_EVENT_IOC_RESET, 0);
            perf_cpu[cpu][i].prev_value = 0;
        }
    }

    for(int cpu = START_INDEX_BIG; cpu <= END_INDEX_BIG; ++cpu)
    {

        for(int i = 0; i < NUM_SOFTWARE_COUNTERS; ++i)
        {
                uint64_t config;
                int group_fd;

                switch(i)
                {
                        case 0:
	                    config = PERF_COUNT_SW_CPU_MIGRATIONS;
	                    group_fd = -1;
                            //group_fd = perf_sw[cpu][0].fd;
	                    break;
                        case 1:
	                    config = PERF_COUNT_SW_CONTEXT_SWITCHES;
	                    group_fd = perf_sw[cpu][0].fd;
	                    break;
                        default:
	                    perf_sw[cpu][i].fd = -1;
	                    perf_sw[cpu][i].id = -1;
	                    continue;
                }

                struct perf_event_attr pe;
                memset(&pe, 0, sizeof(pe));
                pe.size = sizeof(pe);
                pe.type = PERF_TYPE_SOFTWARE;
                pe.config = config;
                pe.exclude_hv = true;
                pe.exclude_kernel = false;
                pe.disabled = true;
                pe.read_format = PERF_FORMAT_ID | PERF_FORMAT_GROUP;

                const auto fd = perf_event_open(&pe, -1, cpu, group_fd, 0);
                if(fd == -1)
                {
                     perror("scheduler: failed to initialise perf");
                     abort();
                }

                perf_sw[cpu][i].fd = fd;
                ioctl(fd, PERF_EVENT_IOC_ID, &perf_sw[cpu][i].id);
                ioctl(fd, PERF_EVENT_IOC_RESET, 0);
                perf_sw[cpu][i].prev_value = 0;
          }
    }

    for(int cpu = START_INDEX_BIG; cpu <= END_INDEX_BIG; ++cpu)
    {
        const auto leader_fd = perf_cpu[cpu][0].fd;
        ioctl(leader_fd, PERF_EVENT_IOC_ENABLE, PERF_IOC_FLAG_GROUP);
    }

    for(int cpu = START_INDEX_BIG; cpu <= END_INDEX_BIG; ++cpu)
    {
        const auto leader_fd = perf_sw[cpu][0].fd;
        ioctl(leader_fd, PERF_EVENT_IOC_ENABLE, PERF_IOC_FLAG_GROUP);
    }
}


void perf_init_biglittle()
{
    auto perf_event_open = [](struct perf_event_attr *hw_event, pid_t pid,
                               int cpu, int group_fd, unsigned long flags) {
        return syscall(__NR_perf_event_open, hw_event, pid, cpu,
                       group_fd, flags);
    };

    num_processors = get_nprocs_conf();
    assert(num_processors <= MAX_PROCESSORS);

    for(int cpu = START_INDEX_LITTLE; cpu <= END_INDEX_LITTLE; ++cpu)
    {
        for(int i = 0; i < MAX_EVENTS_PER_GROUP; ++i)
        {
            uint64_t config;
            int group_fd;
            struct perf_event_attr pe;
            memset(&pe, 0, sizeof(pe));


            switch(i)
            {
                case 0:
		    config = PERF_COUNT_HW_CPU_CYCLES;
		    group_fd = -1;
                    pe.type = PERF_TYPE_HARDWARE;
		    break;
                case 1:
		    config = 0x15;//dcache_evic
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
                case 2:
		    config = 0x04;//data_rw_cache_access
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
		case 3:
                    config = 0x1D;//bus cycle
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
		case 4:
                    config = 0xC1;//no_cache_ext_mem_req
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
                default:
		    perf_cpu[cpu][i].fd = -1;
		    perf_cpu[cpu][i].id = -1;
                    pe.type = PERF_TYPE_RAW;
		    continue;
            }

            pe.size = sizeof(pe);
            //pe.type = PERF_TYPE_RAW;
            pe.config = config;
            pe.exclude_hv = true;
            pe.exclude_kernel = true;
            pe.disabled = true;
            pe.read_format = PERF_FORMAT_ID | PERF_FORMAT_GROUP;

            const auto fd = perf_event_open(&pe, -1, cpu, group_fd, 0);
            if(fd == -1)
            {
                perror("scheduler: failed to initialise perf");
                abort();
            }

            perf_cpu[cpu][i].fd = fd;
            ioctl(fd, PERF_EVENT_IOC_ID, &perf_cpu[cpu][i].id);
            ioctl(fd, PERF_EVENT_IOC_RESET, 0);
            perf_cpu[cpu][i].prev_value = 0;
        }
    }

    for(int cpu = START_INDEX_BIG; cpu <= END_INDEX_BIG; ++cpu)
    {
        for(int i = 0; i < MAX_EVENTS_PER_GROUP; ++i)
        {
            uint64_t config;
            int group_fd;
            struct perf_event_attr pe;
            memset(&pe, 0, sizeof(pe));


            switch(i)
            {
                case 0:
		    config = PERF_COUNT_HW_CPU_CYCLES;
		    group_fd = -1;
                    pe.type = PERF_TYPE_HARDWARE;
		    break;
                case 1:
		    config = 0x48;//L1D_CACHE_INVAL
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
                case 2:
		    config = 0x46;//L1D_CACHE_WB_VICTIM
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
		case 3:
                    config = 0x16;//L2D_CACHE_ACCESS
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
		case 4:
                    config = 0x73;//DP_SPEC
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
		    break;
                case 5:
                    config = 0x01;//L1I_CACHE_REFILL
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
                    break;
                case 6:
                    config = 0x47;//L1D_CACHE_WB_CLEAN
		    group_fd = perf_cpu[cpu][0].fd;
                    pe.type = PERF_TYPE_RAW;
                    break;
                default:
		    perf_cpu[cpu][i].fd = -1;
		    perf_cpu[cpu][i].id = -1;
                    pe.type = PERF_TYPE_RAW;
		    continue;
            }

            pe.size = sizeof(pe);
            //pe.type = PERF_TYPE_RAW;
            pe.config = config;
            pe.exclude_hv = true;
            pe.exclude_kernel = true;
            pe.disabled = true;
            pe.read_format = PERF_FORMAT_ID | PERF_FORMAT_GROUP;

            const auto fd = perf_event_open(&pe, -1, cpu, group_fd, 0);
            if(fd == -1)
            {
                perror("scheduler: failed to initialise perf");
                abort();
            }

            perf_cpu[cpu][i].fd = fd;
            ioctl(fd, PERF_EVENT_IOC_ID, &perf_cpu[cpu][i].id);
            ioctl(fd, PERF_EVENT_IOC_RESET, 0);
            perf_cpu[cpu][i].prev_value = 0;
        }
    }

    for(int cpu = 0; cpu < num_processors; ++cpu)
    {
        const auto leader_fd = perf_cpu[cpu][0].fd;
        ioctl(leader_fd, PERF_EVENT_IOC_ENABLE, PERF_IOC_FLAG_GROUP);
    }

    for(int cpu = 0; cpu < num_processors; ++cpu)
    {
        const auto leader_fd = perf_sw[cpu][0].fd;
        ioctl(leader_fd, PERF_EVENT_IOC_ENABLE, PERF_IOC_FLAG_GROUP);
    }

}

void perf_shutdown()
{
    for(int cpu = 0; cpu < num_processors; ++cpu)
    {
        for(int i = 0; i < MAX_EVENTS_PER_GROUP; ++i)
        {
            const auto fd = perf_cpu[cpu][i].fd;
            if(fd != -1)
            {
                close(perf_cpu[cpu][i].fd);
                perf_cpu[cpu][i].fd = -1;
                perf_cpu[cpu][i].id = -1;
                perf_cpu[cpu][i].prev_value = 0;
            }
        }
    }


    for(int cpu = 0; cpu < num_processors; ++cpu)
    {

        for(int i = 0; i < NUM_SOFTWARE_COUNTERS; ++i)
        {
            close(perf_sw[cpu][i].fd);
            perf_sw[cpu][i].fd = -1;
            perf_sw[cpu][i].id = -1;
            perf_sw[cpu][i].prev_value = 0;
        }
    }
}

int perf_nprocs()
{
    return num_processors;
}

auto perf_consume_hw(int cpu) -> PerfHardwareData
{
    struct
    {
        uint64_t nr;    /* The number of events */
        struct {
            uint64_t value; /* The value of the event */
            uint64_t id;    /* if PERF_FORMAT_ID */
        } values[MAX_EVENTS_PER_GROUP];
    } data;


    assert(cpu < num_processors);
 

    const auto fd = perf_cpu[cpu][0].fd;

    if(fd == -1)
        return PerfHardwareData{};

    if(read(fd, &data, sizeof(data)) == -1)
    {
        perror("scheduler: failed to read hardware counters");
        abort();
    }

    uint64_t counters[MAX_EVENTS_PER_GROUP];
    memset(counters, -1, sizeof(counters));


    for(uint64_t s = 0; s < data.nr; ++s)
    {
        for(int pi = 0; pi < MAX_EVENTS_PER_GROUP; ++pi)
        {
            if(data.values[s].id == perf_cpu[cpu][pi].id)
            {
                const auto value = data.values[s].value;
                const auto prev_value = perf_cpu[cpu][pi].prev_value;
                const auto u64_max = std::numeric_limits<uint64_t>::max();

                if(value >= prev_value)
                {
                    counters[pi] = value - prev_value;
                }
                else
                {
                    counters[pi] = 0;
                    counters[pi] += u64_max - prev_value;
                    counters[pi] += value;
                }

                perf_cpu[cpu][pi].prev_value = value;
            }
        }
    }


    return PerfHardwareData {
        counters[0],
        counters[1],
        counters[2],
        counters[3],
	counters[4],
        counters[5],
        counters[6],
    };
}

auto perf_consume_sw(int cpu) -> PerfSoftwareData
{
    struct
    {
        uint64_t nr;    /* The number of events */
        struct {
            uint64_t value; /* The value of the event */
            uint64_t id;    /* if PERF_FORMAT_ID */
        } values[NUM_SOFTWARE_COUNTERS];
    } data;

    assert(cpu < num_processors);

    const auto fd = perf_sw[cpu][0].fd;

    if(fd == -1)
        return PerfSoftwareData{};

    if(read(fd, &data, sizeof(data)) == -1)
    {
        perror("scheduler: failed to read software counters");
        abort();
    }

    uint64_t counters[NUM_SOFTWARE_COUNTERS];
    memset(counters, -1, sizeof(counters));

    for(uint64_t s = 0; s < data.nr; ++s)
    {
        for(int pi = 0; pi < NUM_SOFTWARE_COUNTERS; ++pi)
        {
            if(data.values[s].id == perf_sw[cpu][pi].id)
            {
                const auto value = data.values[s].value;
                const auto prev_value = perf_sw[cpu][pi].prev_value;
                const auto u64_max = std::numeric_limits<uint64_t>::max();

                if(value >= prev_value)
                {
                    counters[pi] = value - prev_value;
                }
                else
                {
                    counters[pi] = 0;
                    counters[pi] += u64_max - prev_value;
                    counters[pi] += value;
                }

                perf_sw[cpu][pi].prev_value = value;
            }
        }
    }

    return PerfSoftwareData {
        counters[0],
        counters[1],
    };
}
