#include <cstdio>
#include <cstdlib>
#include <cstdarg>
#include <cassert>
#include <cinttypes>
#include <cstring>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/prctl.h>
#include <linux/limits.h>
#include <signal.h> 
#include "perf.hpp"
#include "time.hpp"
#include "states.hpp" 

#define FLAG_ONLY_PARALLEL_REGION 0
#define NUM_EPISODES 1000

char** environ;

static FILE* collect_stream = 0;
static FILE* cpu_utilization_stream = 0;
static int application_pid = -1;
static uint64_t application_start_time = 0;
static State current_state;
static int num_time_steps = 0;
static int flag_update_schedule;

static void update_scheduler_to_serial_region();

void get_cpu_usage(double *cpu_usage)
{
    if(::application_pid == -1)
    {
        cpu_usage[0] = 0.0;
        cpu_usage[1] = 0.0;
        return;
    }

    int count = 0;
    char buffer[256];
    sprintf(buffer, "ps -p %d -mo pcpu,psr", ::application_pid);
    cpu_utilization_stream = popen(buffer, "r");
    if(!cpu_utilization_stream)
    {
        perror("failed to collect cpu usage");
        cpu_usage[0] = 0.0;
        cpu_usage[1] = 0.0;
        return;
    }

    double total_cluster_little = 0.0;
    double total_cluster_big    = 0.0;

    // skip %CPU
    count = 0;
    buffer[0] = 0;
    while(count == 0 || buffer[count-1] != '\n')
    {
        if(!fgets(&buffer[count], sizeof(buffer), cpu_utilization_stream))
            break;
        count = strlen(buffer);
    }

    // skip total
    count = 0;
    buffer[0] = 0;
    while(count == 0 || buffer[count-1] != '\n')
    {
        if(!fgets(&buffer[count], sizeof(buffer), cpu_utilization_stream))
            break;
        count = strlen(buffer);
    }

    // iterate on the next lines
    while(true)
    {
        count = 0;
        buffer[0] = 0;
        while(count == 0 || buffer[count-1] != '\n')
        {
            if(!fgets(&buffer[count], sizeof(buffer), cpu_utilization_stream))
                break;
            count = strlen(buffer);
        }

        if(count == 0)
            break;

        double row_cpu_usage;
        int row_cpu_core;
        sscanf(buffer, "%lf %d", &row_cpu_usage, &row_cpu_core);

        if(row_cpu_core >= 0 && row_cpu_core <= 3)
            total_cluster_little += row_cpu_usage;
        else
            total_cluster_big += row_cpu_usage;
    }

    fclose(cpu_utilization_stream);

    cpu_usage[0] = total_cluster_little;
    cpu_usage[1] = total_cluster_big;

}

static void cleanup()
{
    fprintf(stderr, "scheduler: cleaning up\n");

    if(application_pid != -1)
    {
        kill(application_pid, SIGTERM);
        waitpid(application_pid, nullptr, 0);
        application_pid = -1;
    }

    if(scheduler_pid != -1)
    {
        kill(scheduler_pid, SIGTERM);
        waitpid(scheduler_pid, nullptr, 0);
        scheduler_pid = -1;
    }

    if(scheduler_input_pipe != -1)
    {
        close(scheduler_input_pipe);
        scheduler_input_pipe = -1;
    }

    if(scheduler_output_pipe != -1)
    {
        close(scheduler_output_pipe);
        scheduler_output_pipe = -1;
    }

    if(collect_stream != 0)
    {
        fclose(collect_stream);
        collect_stream = 0;
    }
}

static bool create_logging_file()
{


#ifdef PMCS_A15_ONLY
    char pmcs[10][35]={"0x01_0x02_0x03_0x04_0x05_0x08",
                       "0x09_0x10_0x12_0x13_0x14_0x15",
                       "0x16_0x17_0x18_0x19_0x1B_0x1D",
                       "0x40_0x41_0x42_0x43_0x46_0x47",
                       "0x48_0x4C_0x4D_0x50_0x51_0x52",
                       "0x53_0x56_0x58_0x60_0x61_0x62",
                       "0x64_0x66_0x67_0x68_0x69_0x6A",
                       "0x6C_0x6D_0x6E_0x70_0x71_0x72",
                       "0x73_0x74_0x75_0x76_0x78_0x79",
                       "0x7A_0x7E_0x00_0x00_0x00_0x00"};

#elif defined PMCS_A7_ONLY
    char pmcs[9][35]={"0x01_0x02_0x03_0x04",
                      "0x05_0x06_0x07_0x08",
                      "0x09_0x0A_0x0C_0x0D",
                      "0x0E_0x0F_0x10_0x12",
                      "0x13_0x14_0x15_0x16",
                      "0x17_0x18_0x19_0x1D",
                      "0x60_0x61_0xC0_0xC1",
                      "0xC4_0xC5_0xC6_0xC9",
                      "0xCA_0x00_0x00_0x00"};
#endif

    static int index_pmc=0;
    char filename[PATH_MAX];

#if defined PMCS_A7_ONLY || defined PMCS_A15_ONLY 
    if(index_pmc >=0 && index_pmc<=10){
       sprintf(filename, "%s.csv", pmcs[index_pmc]);
       index_pmc ++;
    }
#else
    sprintf(filename, "scheduler_%d.csv", application_pid); //getpid() get fathers'pid  
#endif


    collect_stream = fopen(filename, "w");
    if(!collect_stream)
    {
        perror("scheduler: failed to open logging file");
        return false;
    }
    fprintf(stderr, "scheduler: collecting to file %s\n", filename);
   
    return true;
}

static bool create_time_file(uint64_t time_ms)
{
    char filename[PATH_MAX];
    sprintf(filename, "scheduler_%d.time", getpid());
    FILE* time_stream = fopen(filename, "w");
    if(!time_stream)
    {
        perror("scheduler: failed to open time file");
        return false;
    }
    fprintf(time_stream, "%" PRIu64, time_ms);
    fprintf(time_stream, "\n");
    return true;
}


static bool spawn_application(char* argv[])
{
    int pid = fork();
    if(pid == -1)
    {
        perror("scheduler: failed to fork scheduled application");
        return false;
    }
    else if(pid == 0)
    {
        execvp(argv[0], argv);
        perror("scheduler: execvp failed");
        return false;
    }
    else
    {
        ::application_pid = pid;
        ::application_start_time = get_time();
        ::current_state = STATE_4b;
        //update_scheduler_to_serial_region();
        return true;
    }
}


static void update_scheduler_to_serial_region()
{
//    if(::application_pid != -1 && current_state != STATE_4b)
    if(::application_pid != -1)
    {
        char buffer[512];
        auto cfg = configs[STATE_4b];

        sprintf(buffer, "taskset -pac %s %d >/dev/null", cfg, application_pid);

        int status = system(buffer);
        if(status == -1)
        {
            perror("scheduler: system() failed");
        }
        else if(status != 0)
        {
            fprintf(stderr, "scheduler: taskset returned %d :(\n", status);
        }

        current_state = STATE_4b;
    }

}

static void update_scheduler()
{
    double cpu_usage[2];
    get_cpu_usage(cpu_usage);


    double l_pmc_1 = 0;
    double l_pmc_2 = 0;
    double l_pmc_3 = 0;
    double l_pmc_4 = 0;
    double l_pmc_5 = 0;

    double b_pmc_1 = 0;
    double b_pmc_2 = 0;
    double b_pmc_3 = 0;
    double b_pmc_4 = 0;
    double b_pmc_5 = 0;
    double b_pmc_6 = 0;
    double b_pmc_7 = 0;

  
    //l_pmc or b_pmc are sum all core in cluster
    for(int cpu = START_INDEX_LITTLE; cpu <= END_INDEX_LITTLE; ++cpu)
    {
        const auto hw_data = perf_consume_hw(cpu);
        l_pmc_1 += (double)hw_data.pmc_1;   
        l_pmc_2 += (double)hw_data.pmc_2;   
        l_pmc_3 += (double)hw_data.pmc_3;   
        l_pmc_4 += (double)hw_data.pmc_4;   
        l_pmc_5 += (double)hw_data.pmc_5;   

    }

    for(int cpu = START_INDEX_BIG; cpu < END_INDEX_BIG; ++cpu)
    {
        const auto hw_data = perf_consume_hw(cpu);
        b_pmc_1 += (double)hw_data.pmc_1;   
        b_pmc_2 += (double)hw_data.pmc_2;   
        b_pmc_3 += (double)hw_data.pmc_3;   
        b_pmc_4 += (double)hw_data.pmc_4;   
        b_pmc_5 += (double)hw_data.pmc_5;   
        b_pmc_6 += (double)hw_data.pmc_6;   
        b_pmc_7 += (double)hw_data.pmc_7;   

    }

    double total_cpu_migration = 0;
    double total_context_switch = 0;


    for(int cpu = 0, max_cpu = perf_nprocs(); cpu < max_cpu; ++cpu)
    {
        const auto sw_data = perf_consume_sw(cpu);
        total_cpu_migration += (double)sw_data.cpu_migrations;
        total_context_switch += (double)sw_data.context_switches;
    }

    const uint64_t elapsed_time = to_millis(get_time() - ::application_start_time);
    State next_state = current_state;



#ifdef PMCS_A15_ONLY   
    fprintf(collect_stream, "%" PRIu64 \
                            ",%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf," \
                            "%.2lf,%.2lf,%.2lf,%.2lf\n" ,
                            elapsed_time, \
                            b_pmc_1, b_pmc_2, b_pmc_3, b_pmc_4, b_pmc_5, b_pmc_6, b_pmc_7, \
                            total_cpu_migration, total_context_switch, cpu_usage[0], cpu_usage[1]);


#elif defined PMCS_A7_ONLY        
    fprintf(collect_stream, "%" PRIu64 \
                            ",%.2lf,%.2lf,%.2lf,%.2lf,%.2lf," \
                            "%.2lf,%.2lf,%.2lf,%.2lf\n" ,
                            elapsed_time, \
                            l_pmc_1, l_pmc_2, l_pmc_3, l_pmc_4, l_pmc_5, \
                            total_cpu_migration, total_context_switch, cpu_usage[0], cpu_usage[1]);


#else
    fprintf(stderr,"%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf,%.2lf," \
                   "%.2lf,%.2lf,%.2lf,%.2lf\n", \
                   l_pmc_1, l_pmc_2, l_pmc_3, l_pmc_4, l_pmc_5, \
                   b_pmc_1, b_pmc_2, b_pmc_3, b_pmc_4, b_pmc_5, b_pmc_6, b_pmc_7, \
                   total_cpu_migration, total_context_switch, cpu_usage[0], cpu_usage[1]);

    fprintf(collect_stream, "%" PRIu64 \
                            ",%lf,%lf,%lf,%lf,%lf," \
                            "%lf,%lf,%lf,%lf,%lf,%lf,%lf," \
                            "%.2lf,%.2lf,%.2lf,%.2lf\n" ,
                            elapsed_time, \
                            l_pmc_1, l_pmc_2, l_pmc_3, l_pmc_4, l_pmc_5, \
                            b_pmc_1, b_pmc_2, b_pmc_3, b_pmc_4, b_pmc_5, b_pmc_6, b_pmc_7, \
                            total_cpu_migration, total_context_switch, cpu_usage[0], cpu_usage[1]);
   
}


void sig_handler(int signo)
{
    if (signo == SIGUSR1){
       fprintf(stderr, "received SIGUSR1\n");
        if(FLAG_ONLY_PARALLEL_REGION == 1){
             update_scheduler();
             ::flag_update_schedule = 0;
        }

    }
    else if (signo == SIGUSR2){
       fprintf(stderr, "received SIGUSR2\n"); 

       if(FLAG_ONLY_PARALLEL_REGION == 1){
          ::flag_update_schedule = 1;
          fprintf(collect_stream, "\n"); 
       }
       //update_scheduler_to_serial_region();
    }
}


int main(int argc, char* argv[])
{

    ::flag_update_schedule = FLAG_ONLY_PARALLEL_REGION ;
    signal(SIGUSR1, sig_handler);
    signal(SIGUSR2, sig_handler);

    if(argc < 2)
    {
        fprintf(stderr, "usage: %s command args...\n", argv[0]);
        return 1;
    }

#if defined PMCS_A15_ONLY
    const int num_episodes = 10;//number of time to collect all pmcs from big core
#elif defined PMCS_A7_ONLY
    const int num_episodes = 9;//number of time to collect all pmcs from little core
#else
    const int num_episodes = 1;

    for(int curr_episode = 0; curr_episode < num_episodes; ++curr_episode)
    {
        perf_init();

        if(!create_logging_file())
        {
            cleanup();
            return 1;
        }
        if(!spawn_application(&argv[1]))
        {
            cleanup();
            return 1;
        }

        fprintf(stderr, "\n\nscheduler: starting episode %d with pid %d\n\n", curr_episode + 1, application_pid);

        while(::application_pid != -1)
        {
            int pid = waitpid(::application_pid, NULL, WNOHANG);

            if(pid == -1)
            {
                perror("scheduler: waitpid in main loop failed");
            }
            else if(pid != 0)
            {
                assert(pid == ::application_pid);
                application_pid = -1;

            }
            #if SCHEDULER_TYPE == SCHEDULER_TYPE_COLLECT
            else if(!(flag_update_schedule == 1))
            {
                update_scheduler();
            }
            #endif
            usleep(200000);//20 miliseconds
        }

        perf_shutdown();


        create_time_file(to_millis(get_time() - ::application_start_time));
 
        usleep(5000000); //only to clear anything in cpu - 2 seconds
        fprintf(stderr, "scheduler: episode %d finished\n", curr_episode + 1);
    }

    cleanup();
    return 0;
}
