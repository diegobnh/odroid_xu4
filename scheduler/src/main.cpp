#include <string.h>
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
#include <iostream>
#include <fcntl.h>
#include <time.h>
#include "perf.hpp"
#include "time.hpp"
#include "states.hpp" 

#define TOTAL_DIFFERENT_PMCS 20

enum { MAX_ARGS = 64 };
char *args[MAX_ARGS];
char **next = ::args;

char** environ;

static FILE* collect_stream = 0;
static FILE* cpu_utilization_stream = 0;
static int predictor_input_pipe = -1;
static int predictor_output_pipe = -1;
static int predictor_pid = -1;
static int application_pid = -1;
static uint64_t application_start_time = 0;
static State current_state;
static int flag_update_schedule;
static int save_application_pid;
static void update_scheduler_to_serial_region();
static int change_config = 0;
static double sum_time=0;
static unsigned int  count_time=0;

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
    //fprintf(stderr, "Inside CPU utilization Little:%lf\t Big:%lf  Current_state:%d\n", cpu_usage[0], cpu_usage[1], current_state);
}



void get_input(char *line) {        
    char *temp = NULL;
    
    temp = strtok(line, " ");
    while (temp != NULL)
    {
        *next++ = temp; //this is global variable
        temp = strtok(NULL, " ");
    }
    *next = NULL;
    

}

static void send_to_scheduler(const char* fmt, ...)
{
    char buffer[512];

    va_list va;
    va_start(va, fmt);
    int count = vsnprintf(buffer, sizeof(buffer) - 1, fmt, va);
    va_end(va);

    if(count < 0)
    {
        perror("scheduler: failed to vsnprintf during send_to_scheduler");
        abort();
    }
    else
    {
        buffer[count++] = '\n';
        buffer[count] = '\0';

        int written = write(predictor_input_pipe, buffer, count);
        if(written == -1)
        {
            perror("scheduler: failed to write to scheduler");
            abort();
        }
        else if(written != count)
        {
            fprintf(stderr, "scheduler: count mismatch during send_to_scheduler\n");
            abort();
        }
    }
}

static void recv_from_scheduler(const char* fmt, ...)
{
    int count = 0;
    char buffer[512];

    while(count == 0 || buffer[count-1] != '\n')
    {
        const auto result = read(predictor_output_pipe, buffer, sizeof(buffer) - count);
        if(result <= 0)
        {
            perror("scheduler: failed to read from scheduler pipe\n");
            abort();
        }

        count += result;
        assert(count < (int) sizeof(buffer) - 1);
    }

    va_list va;
    va_start(va, fmt);
    vsscanf(buffer, fmt, va);
    va_end(va);
}

static void cleanup()
{

    if(application_pid != -1)
    {
        kill(application_pid, SIGTERM);
        waitpid(application_pid, nullptr, 0);
        application_pid = -1;
    }

    if(predictor_pid != -1)
    {
        kill(predictor_pid, SIGTERM);
        waitpid(predictor_pid, nullptr, 0);
        predictor_pid = -1;
    }


    if(predictor_input_pipe != -1)
    {
        close(predictor_input_pipe);
        predictor_input_pipe = -1;
    }


    if(predictor_output_pipe != -1)
    {
        close(predictor_output_pipe);
        predictor_output_pipe = -1;
    }

    if(collect_stream != 0)
    {
        fclose(collect_stream);
        collect_stream = 0;
    }

}

static bool create_logging_file()
{
    char filename[PATH_MAX];

    sprintf(filename, "scheduler_%d.csv", application_pid); //getpid() get fathers'pid  

    collect_stream = fopen(filename, "w");
    if(!collect_stream)
    {
        perror("scheduler: failed to open logging file");
        return false;
    }
    fprintf(stderr, "scheduler: collecting to file %s\n", filename);
    //fprintf(collect_stream, "#ElapsedTime,L_cycles,L_pmc1,L_pmc2,L_pmc3,L_pmc4,B_cycles,B_pmc1,B_pmc2,B_pmc3,B_pmc4,B_pmc5,B_pmc6,CpuMigration,ContextSwitch,LittleUtilization,BigUtilization\n") ;

    return true;
}

static bool create_time_file(uint64_t time_ms)
{
    char filename[PATH_MAX];
    sprintf(filename, "scheduler_%d.time", save_application_pid);
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

static bool spawn_predictor(const char* command)
{
    int inpipefd[2] = {-1, -1};
    int outpipefd[2] = {-1, -1};

    if(pipe(inpipefd) == -1 || pipe(outpipefd) == -1)
    {
        perror("scheduler: failed to create scheduling pipes.");
        return false;
    }

    int pid = fork();
    if(pid == -1)
    {
        perror("scheduler: failed to fork scheduler");
        close(inpipefd[0]);
        close(inpipefd[1]);
        close(outpipefd[0]);
        close(outpipefd[1]);
        return false;
    }
    else if(pid == 0)
    {
        dup2(outpipefd[0], STDIN_FILENO);
        dup2(inpipefd[1], STDOUT_FILENO);

        close(outpipefd[1]);
        close(inpipefd[0]);

        // receive SIGTERM once the parent process dies
        prctl(PR_SET_PDEATHSIG, SIGTERM);

        execl("/bin/sh", "sh", "-c", command, NULL);
        perror("scheduler: execl failed");
        return false;
    }
    else
    {
        close(outpipefd[0]);
        close(inpipefd[1]);
        ::predictor_pid = pid;
        ::predictor_input_pipe = outpipefd[1];
        ::predictor_output_pipe = inpipefd[0];
        return true;
    } 
}

static bool spawn_application(char* apps)
{

    int pid = fork();
    if(pid == -1)
    {
        perror("scheduler: failed to fork scheduled application");
        return false;
    }
    else if(pid == 0)
    {
        get_input(apps);
        execvp(args[0], args);
        perror("scheduler: execvp failed");
        return false;
    }
    else
    {
        ::application_pid = pid;
        ::application_start_time = get_time();
        ::current_state = STATE_4l4b;
        update_scheduler_to_serial_region();
        return true;
    }
}


static void update_scheduler_to_serial_region()
{
    if(::application_pid != -1)
    {
        char buffer[512];
        auto cfg = configs[STATE_4l4b];

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

        current_state = STATE_4l4b;
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

    if(current_state==STATE_4l)
    {

        for(int cpu = START_INDEX_LITTLE; cpu <= END_INDEX_LITTLE; ++cpu)
        {
           const auto hw_data = perf_consume_hw(cpu);
           l_pmc_1 += (double)hw_data.pmc_1;
           l_pmc_2 += (double)hw_data.pmc_2;
           l_pmc_3 += (double)hw_data.pmc_3;
           l_pmc_4 += (double)hw_data.pmc_4;
           l_pmc_5 += (double)hw_data.pmc_5;
        }
    }

    if(current_state==STATE_4b)
    {
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
    }

   if(current_state==STATE_4l4b){

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
    }


    if(current_state==STATE_4l4b  && (l_pmc_1 < 0.000001 || b_pmc_1 < 0.000001))
    {
        return;
    }
    else if(current_state==STATE_4l && l_pmc_1 < 0.000001){
        return;
    }
    else if(current_state==STATE_4b && b_pmc_1 < 0.000001){
        return;
    }

    const uint64_t elapsed_time = to_millis(get_time() - ::application_start_time);
    State next_state = current_state;

    int state_index_reply;
    float exec_time = -1.0;


    send_to_scheduler("%.6lf,%.6lf,%.6lf,%.6lf,%.6lf,%.6lf,%.6lf,%.6lf,%.6lf,%.6lf,%.6lf,%.6lf,%d", \
                      l_pmc_1, l_pmc_2, l_pmc_3, l_pmc_4, l_pmc_5, \
                      b_pmc_1, b_pmc_2, b_pmc_3, b_pmc_4, b_pmc_5, b_pmc_6, b_pmc_7, \
                      current_state);

    clock_t start, end;
    start = clock();
    recv_from_scheduler("%d", &state_index_reply);//Here is State enumerate
    end = clock()-start;
    sum_time += ((double)end)/CLOCKS_PER_SEC; // in seconds
    ::count_time+=1;

    next_state = static_cast<State>(state_index_reply);

    if(::application_pid != -1 && next_state != current_state)
    {
        char buffer[512];
        auto cfg = configs[next_state];//extern variable declared in States.h

        sprintf(buffer, "taskset -pac %s %d >/dev/null", cfg, application_pid);
        //fprintf(stderr, "scheduler: %s\n", buffer);


        perf_shutdown();
        if(next_state == STATE_4l)
        {
            perf_init_little();
        }
        else if (next_state == STATE_4b)
        {
            perf_init_big();
        }
        else if (next_state == STATE_4l4b)
        {
            perf_init_biglittle();
        }


        int status = system(buffer);
        if(status == -1)
        {
            perror("scheduler: system() failed");
        }
        else if(status != 0)
        {
            fprintf(stderr, "scheduler: taskset returned %d :(\n", status);
        }

        current_state = next_state;
        ::change_config++;
    }
}


int main(int argc, char* argv[])
{
    unsigned int pmcs_values[TOTAL_DIFFERENT_PMCS];
    int total_apps=12;
    unsigned int value;

    char commands[][256]={"/home/odroid/workloads/bots/bin/fib.gcc.omp-tasks-tied -o 0 -n 36",
                          "/home/odroid/workloads/bots/bin/nqueens.gcc.omp-tasks-tied -n 13",
                          "/home/odroid/workloads/bots/bin/health.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/health/medium.input",
                          "/home/odroid/workloads/bots/bin/floorplan.gcc.omp-tasks-tied -o 0 -f /home/odroid/workloads/bots/inputs/floorplan/input.20",
                          "/home/odroid/workloads/bots/bin/fft.gcc.omp-tasks-tied -o 0 -n 10000000",
                          "/home/odroid/workloads/bots/bin/sort.gcc.omp-tasks-tied -o 0 -n 100000000",
                          "/home/odroid/workloads/bots/bin/sparselu.gcc.for-omp-tasks-tied -o 0 -n 100 -m 100",
                          "/home/odroid/workloads/bots/bin/strassen.gcc.omp-tasks-tied -o 0 -n 4096",
                          "/home/odroid/workloads/rodinia/openmp/backprop/backprop 10000000",
                          "/home/odroid/workloads/rodinia/openmp/heartwall/heartwall /home/odroid/workloads/rodinia/data/heartwall/test.avi.part00 50",
                          "/home/odroid/workloads/rodinia/openmp/lavaMD/lavaMD -boxes1d 20",
                          "/home/odroid/workloads/rodinia/openmp/particlefilter/./particle_filter -x 512 -y 512 -z 40 -np 40000"};

   
   char apps_name[][30]={"fib",
                         "nqueens",
                         "health",
                         "floorplan",
                         "fft",
                         "sort",
                         "sparselu",
                         "strassen",
                         "backprop",
                         "heartwall",
                         "lavaMD",
                         "particle_filter"}; 


    FILE *fp_pmcs = fopen("pmcs.txt", "r");
    if (fp_pmcs == NULL) {
        fprintf(stderr, "Can't read pmcs.txt");
        return 0;
    }

    if(!spawn_predictor("python3 ./predictor.py"))
    {
        fprintf(stderr,"Spawn predictor\n");
        cleanup();
        return 1;
    }
    usleep(5000000);

    //read the first 14 pmcs , after read more 14 pmcs..
    int k=0;
    while(fscanf(fp_pmcs, "%x,", &value) == 1 && k<TOTAL_DIFFERENT_PMCS) {//20 is total pmcs : four to little, six to big and ten to biglittle(fisrt 4 for little after 6 for big)
           pmcs_values[k]=value;
           k++;
    }

    set_pmcs(pmcs_values,TOTAL_DIFFERENT_PMCS);


    for(int i = 0; i < total_apps; ++i)
    {
        ::change_config=0;
        if(!spawn_application(commands[i]))
        {
            fprintf(stderr,"Spawn application\n");
            cleanup();
            return 1;
        }
        ::save_application_pid = ::application_pid;

        perf_init_biglittle();

        char buf[50];

        while(::application_pid != -1)
        {
            int pid = waitpid(::application_pid, NULL, WNOHANG);
            if(pid == -1)
            {
                perror("scheduler: waitpid in main loop failed");
            }
            else if(pid == 0)
            {
                update_scheduler();
            }
            else
            {
                assert(pid == ::application_pid);
                application_pid = -1;

                update_scheduler();

                float exec_time;
                //int state_index_reply;
                if(::application_pid == -1) // end of episode
                {
                     exec_time = to_millis(get_time() - ::application_start_time);
                     fprintf(stderr, "%s,%lf,%d\n", apps_name[i],exec_time*0.001,::change_config);
                     //create_time_file(exec_time);
                     send_to_scheduler("0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-1");
                     //fprintf(stderr, "Average time spend model:%lf\n",sum_time/count_time); 
                     ::sum_time=0.0;
                     ::count_time=0.0;
                }
            }
            usleep(200000);//200 miliseconds
        }
        usleep(5000000);
        perf_shutdown();

        //sprintf(buf, "mv output_predictor.txt %s", apps_name[i]);
        //system(buf);
    }
    cleanup();
    usleep(200000);//200 miliseconds
  
    return 0;
}
