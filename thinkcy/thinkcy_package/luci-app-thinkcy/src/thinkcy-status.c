/**
 * thinkcy-status - ThinkCy status checker
 * 
 * Compile: gcc -Wall -Os -o thinkcy-status thinkcy-status.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <ctype.h>

#define CONFIG_FILE "/etc/config/thinkcy"
#define LOG_FILE "/var/log/thinkcy.log"
#define PID_FILE "/var/run/thinkcy.pid"
#define BUFFER_SIZE 1024

// Color codes for terminal output
#define COLOR_RESET   "\033[0m"
#define COLOR_RED     "\033[31m"
#define COLOR_GREEN   "\033[32m"
#define COLOR_YELLOW  "\033[33m"
#define COLOR_BLUE    "\033[34m"
#define COLOR_MAGENTA "\033[35m"
#define COLOR_CYAN    "\033[36m"

typedef struct {
    int clash_enabled;
    int vpn_enabled;
    int ddns_enabled;
} Config;

typedef struct {
    int clash_running;
    int vpn_running;
    int ddns_running;
    int thinkcy_running;
} Status;

// Function prototypes
int check_service_running(const char *service);
int check_service_enabled(const char *service);
int read_config(Config *config);
int check_status(Status *status);
void print_colored(const char *color, const char *text);
void print_service_status(const char *name, int enabled, int running);
void print_help(void);
void print_version(void);
void show_logs(int lines);
void show_config(void);
void restart_thinkcy(void);
void print_system_info(void);

int main(int argc, char *argv[]) {
    Config config = {0};
    Status status = {0};
    
    // Parse command line arguments
    if (argc > 1) {
        if (strcmp(argv[1], "clash") == 0) {
            read_config(&config);
            int running = check_service_running("clash");
            print_service_status("Clash", config.clash_enabled, running);
            return running ? 0 : 1;
        }
        else if (strcmp(argv[1], "vpn") == 0) {
            read_config(&config);
            int running = check_service_running("openvpn");
            print_service_status("VPN", config.vpn_enabled, running);
            return running ? 0 : 1;
        }
        else if (strcmp(argv[1], "ddns") == 0) {
            read_config(&config);
            int running = check_service_running("ddns");
            print_service_status("DDNS", config.ddns_enabled, running);
            return running ? 0 : 1;
        }
        else if (strcmp(argv[1], "log") == 0) {
            int lines = 20;
            if (argc > 2) {
                lines = atoi(argv[2]);
                if (lines <= 0) lines = 20;
            }
            show_logs(lines);
            return 0;
        }
        else if (strcmp(argv[1], "config") == 0) {
            show_config();
            return 0;
        }
        else if (strcmp(argv[1], "restart") == 0) {
            restart_thinkcy();
            return 0;
        }
        else if (strcmp(argv[1], "system") == 0) {
            print_system_info();
            return 0;
        }
        else if (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) {
            print_help();
            return 0;
        }
        else if (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-v") == 0) {
            print_version();
            return 0;
        }
        else {
            fprintf(stderr, "Unknown command: %s\n", argv[1]);
            fprintf(stderr, "Use --help for usage information\n");
            return 1;
        }
    }
    
    // Default: show full status
    printf("%sThinkCy Service Status%s\n", COLOR_CYAN, COLOR_RESET);
    printf("=======================\n\n");
    
    // Read configuration
    if (!read_config(&config)) {
        printf("%sWarning: Could not read configuration%s\n", COLOR_YELLOW, COLOR_RESET);
    }
    
    // Check service status
    check_status(&status);
    
    // Print service status
    printf("%sService Status:%s\n", COLOR_BLUE, COLOR_RESET);
    printf("---------------\n");
    print_service_status("ThinkCy", 1, status.thinkcy_running);
    print_service_status("Clash", config.clash_enabled, status.clash_running);
    print_service_status("VPN", config.vpn_enabled, status.vpn_running);
    print_service_status("DDNS", config.ddns_enabled, status.ddns_running);
    
    // Print configuration summary
    printf("\n%sConfiguration:%s\n", COLOR_BLUE, COLOR_RESET);
    printf("--------------\n");
    printf("Clash enabled: %s\n", config.clash_enabled ? "Yes" : "No");
    printf("VPN enabled:   %s\n", config.vpn_enabled ? "Yes" : "No");
    printf("DDNS enabled:  %s\n", config.ddns_enabled ? "Yes" : "No");
    
    // Print system info
    printf("\n%sSystem Info:%s\n", COLOR_BLUE, COLOR_RESET);
    printf("------------\n");
    
    time_t now = time(NULL);
    char time_str[64];
    strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", localtime(&now));
    printf("Current time:  %s\n", time_str);
    
    // Check uptime
    FILE *fp = fopen("/proc/uptime", "r");
    if (fp) {
        double uptime;
        fscanf(fp, "%lf", &uptime);
        fclose(fp);
        
        int days = (int)uptime / 86400;
        int hours = ((int)uptime % 86400) / 3600;
        int minutes = ((int)uptime % 3600) / 60;
        
        printf("System uptime: %d days, %d hours, %d minutes\n", days, hours, minutes);
    }
    
    // Check memory
    fp = fopen("/proc/meminfo", "r");
    if (fp) {
        char line[256];
        long total_mem = 0, free_mem = 0;
        
        while (fgets(line, sizeof(line), fp)) {
            if (strstr(line, "MemTotal:")) {
                sscanf(line, "MemTotal: %ld kB", &total_mem);
            } else if (strstr(line, "MemFree:")) {
                sscanf(line, "MemFree: %ld kB", &free_mem);
            }
        }
        fclose(fp);
        
        if (total_mem > 0) {
            long used_mem = total_mem - free_mem;
            float usage_percent = (float)used_mem / total_mem * 100;
            printf("Memory usage:  %.1f%% (%.1f/%.1f MB)\n", 
                   usage_percent, 
                   used_mem / 1024.0, 
                   total_mem / 1024.0);
        }
    }
    
    printf("\n%sCommands:%s\n", COLOR_BLUE, COLOR_RESET);
    printf("---------\n");
    printf("thinkcy-status clash    - Check Clash status\n");
    printf("thinkcy-status vpn      - Check VPN status\n");
    printf("thinkcy-status ddns     - Check DDNS status\n");
    printf("thinkcy-status log [n]  - Show last n log lines\n");
    printf("thinkcy-status config   - Show configuration\n");
    printf("thinkcy-status restart  - Restart ThinkCy service\n");
    printf("thinkcy-status --help   - Show help\n");
    
    return 0;
}

int check_service_running(const char *service) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "/etc/init.d/%s status 2>/dev/null | grep -q 'running'", service);
    
    int result = system(cmd);
    return (result == 0);
}

int check_service_enabled(const char *service) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "ls -la /etc/rc.d/ | grep -q 'S[0-9][0-9]%s'", service);
    
    int result = system(cmd);
    return (result == 0);
}

int read_config(Config *config) {
    FILE *fp = fopen(CONFIG_FILE, "r");
    if (!fp) {
        return 0;
    }
    
    char line[BUFFER_SIZE];
    while (fgets(line, sizeof(line), fp)) {
        // Remove trailing newline
        line[strcspn(line, "\n")] = 0;
        
        // Skip comments and empty lines
        if (line[0] == '#' || line[0] == '\0') {
            continue;
        }
        
        // Parse configuration lines
        if (strstr(line, "option clash_enable")) {
            char *value = strchr(line, '\'');
            if (value) {
                value++;
                config->clash_enabled = (strncmp(value, "1", 1) == 0);
            }
        }
        else if (strstr(line, "option vpn_enable")) {
            char *value = strchr(line, '\'');
            if (value) {
                value++;
                config->vpn_enabled = (strncmp(value, "1", 1) == 0);
            }
        }
        else if (strstr(line, "option ddns_enable")) {
            char *value = strchr(line, '\'');
            if (value) {
                value++;
                config->ddns_enabled = (strncmp(value, "1", 1) == 0);
            }
        }
    }
    
    fclose(fp);
    return 1;
}

int check_status(Status *status) {
    status->thinkcy_running = check_service_running("thinkcy");
    status->clash_running = check_service_running("clash");
    status->vpn_running = check_service_running("openvpn");
    status->ddns_running = check_service_running("ddns");
    
    return 1;
}

void print_colored(const char *color, const char *text) {
    printf("%s%s%s", color, text, COLOR_RESET);
}

void print_service_status(const char *name, int enabled, int running) {
    printf("%-15s: ", name);
    
    if (running) {
        print_colored(COLOR_GREEN, "Running");
    } else {
        print_colored(COLOR_RED, "Stopped");
    }
    
    if (enabled) {
        print_colored(COLOR_YELLOW, " (Enabled)");
    } else {
        printf(" (Disabled)");
    }
    
    printf("\n");
}

void print_help(void) {
    printf("ThinkCy Status Checker - Version 1.0.0\n");
    printf("Usage: thinkcy-status [COMMAND]\n\n");
    printf("Commands:\n");
    printf("  (no command)    Show full status report\n");
    printf("  clash           Check Clash service status\n");
    printf("  vpn             Check VPN service status\n");
    printf("  ddns            Check DDNS service status\n");
    printf("  log [LINES]     Show log entries (default: 20)\n");
    printf("  config          Show configuration file\n");
    printf("  restart         Restart ThinkCy service\n");
    printf("  system          Show system information\n");
    printf("  -h, --help      Show this help message\n");
    printf("  -v, --version   Show version information\n\n");
    printf("Examples:\n");
    printf("  thinkcy-status            # Full status report\n");
    printf("  thinkcy-status log 50     # Show last 50 log lines\n");
    printf("  thinkcy-status clash      # Check only Clash status\n");
}

void print_version(void) {
    printf("thinkcy-status v1.0.0\n");
    printf("ThinkCy Service Manager for OpenWrt\n");
    printf("Copyright (C) 2024 ThinkCy Team\n");
    printf("License: GPL-3.0\n");
}

void show_logs(int lines) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "tail -n %d %s 2>/dev/null || echo 'Log file not found'", 
             lines, LOG_FILE);
    
    system(cmd);
}

void show_config(void) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "cat %s 2>/dev/null || echo 'Config file not found'", 
             CONFIG_FILE);
    
    system(cmd);
}

void restart_thinkcy(void) {
    printf("Restarting ThinkCy service...\n");
    system("/etc/init.d/thinkcy restart");
    
    // Wait a bit and check status
    sleep(2);
    
    if (check_service_running("thinkcy")) {
        printf("%sThinkCy service restarted successfully%s\n", COLOR_GREEN, COLOR_RESET);
    } else {
        printf("%sWarning: ThinkCy service may not be running%s\n", COLOR_YELLOW, COLOR_RESET);
    }
}

void print_system_info(void) {
    printf("%sSystem Information%s\n", COLOR_CYAN, COLOR_RESET);
    printf("===================\n\n");
    
    // Execute system commands and capture output
    const char *commands[] = {
        "uname -a",
        "cat /etc/openwrt_release 2>/dev/null || echo 'Not an OpenWrt system'",
        "free -m | grep '^Mem:' | awk '{printf \"Memory: %s/%s MB (%.1f%% used)\\n\", $3, $2, $3/$2*100}'",
        "df -h / | tail -1 | awk '{printf \"Root FS: %s/%s (%s used)\\n\", $3, $2, $5}'",
        "uptime",
        "date",
        NULL
    };
    
    for (int i = 0; commands[i] != NULL; i++) {
        FILE *fp = popen(commands[i], "r");
        if (fp) {
            char buffer[256];
            while (fgets(buffer, sizeof(buffer), fp)) {
                printf("%s", buffer);
            }
            pclose(fp);
        }
    }
}
