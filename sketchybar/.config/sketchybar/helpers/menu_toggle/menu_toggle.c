// State transitions adapted from malpern/sketchybar-toggle (MIT); see LICENSE.
// Coordinate SketchyBar with the auto-hiding native menu bar without event taps.
#include <ApplicationServices/ApplicationServices.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <signal.h>
#include <spawn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

extern char **environ;
static volatile sig_atomic_t stopped;
static const char *bar = "sketchybar";
static bool debug;

static void stop(int signal_number) { (void)signal_number; stopped = 1; }
static double now(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1e9;
}
static bool command(char *const arguments[]) {
    pid_t pid;
    if (posix_spawnp(&pid, bar, NULL, NULL, arguments, environ)) return false;
    int status;
    while (waitpid(pid, &status, 0) < 0) {
        if (errno != EINTR) return false;
    }
    return WIFEXITED(status) && WEXITSTATUS(status) == 0;
}
static bool visible(bool show) {
    if (debug) fprintf(stderr, "menu-toggle: %s\n", show ? "show" : "hide");
    char *hide[] = {(char *)bar, "--bar", "hidden=on", "y_offset=0", NULL};
    char *reveal[] = {(char *)bar, "--bar", "hidden=off", "y_offset=-50", NULL};
    char *animate[] = {(char *)bar, "--animate", "sin", "12", "--bar", "y_offset=0", NULL};
    return show ? command(reveal) && command(animate) : command(hide);
}
static double number(const char *value) {
    char *end;
    double n = strtod(value, &end);
    if (!*value || *end || !isfinite(n) || n < 0) {
        fprintf(stderr, "Invalid nonnegative number: %s\n", value);
        exit(2);
    }
    return n;
}
int main(int argc, char **argv) {
    double trigger = 10, height = 50, debounce = .150;
    const char *lock_path = NULL;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) {
            puts("sb-menu-toggle [--trigger-zone px] [--menu-bar-height px] [--debounce ms]\n"
                 "               [--lock-file path] [--debug]\n"
                 "Requires SketchyBar topmost=window and native menu bar auto-hide.\n"
                 "No Accessibility or Input Monitoring permissions required.");
            return 0;
        } else if (!strcmp(argv[i], "--debug")) debug = true;
        else if (i + 1 < argc && !strcmp(argv[i], "--lock-file")) lock_path = argv[++i];
        else if (i + 1 < argc && !strcmp(argv[i], "--trigger-zone")) trigger = number(argv[++i]);
        else if (i + 1 < argc && !strcmp(argv[i], "--menu-bar-height")) height = number(argv[++i]);
        else if (i + 1 < argc && !strcmp(argv[i], "--debounce")) debounce = number(argv[++i]) / 1000;
        else { fprintf(stderr, "Unknown or incomplete argument: %s\n", argv[i]); return 2; }
    }
    if (height < trigger) { fputs("Menu bar height must be >= trigger zone\n", stderr); return 2; }
    // Hold the lock for our lifetime; reloads must not create competing daemons.
    int lock_fd = -1;
    if (lock_path) {
        lock_fd = open(lock_path, O_CREAT | O_RDWR, 0600);
        if (lock_fd < 0) { perror("lock file"); return 1; }
        if (flock(lock_fd, LOCK_EX | LOCK_NB)) {
            if (errno == EWOULDBLOCK) return 0;
            perror("flock"); return 1;
        }
        fcntl(lock_fd, F_SETFD, FD_CLOEXEC);
    }
    if (!access("/opt/homebrew/bin/sketchybar", X_OK)) bar = "/opt/homebrew/bin/sketchybar";
    else if (!access("/usr/local/bin/sketchybar", X_OK)) bar = "/usr/local/bin/sketchybar";
    signal(SIGINT, stop);
    signal(SIGTERM, stop);
    bool hidden = false, was_down = false;
    double deadline = 0;
    if (!visible(true)) return 1;
    while (!stopped) {
        CGEventRef event = CGEventCreate(NULL);
        if (!event) break;
        CGPoint mouse = CGEventGetLocation(event); // Global display coordinates: top-left origin.
        CFRelease(event);
        CGDirectDisplayID displays[32];
        uint32_t count = 0;
        if (CGGetDisplaysWithPoint(mouse, 32, displays, &count) == kCGErrorSuccess && count) {
            double distance = mouse.y - CGRectGetMinY(CGDisplayBounds(displays[0]));
            bool down = CGEventSourceButtonState(kCGEventSourceStateCombinedSessionState, kCGMouseButtonLeft);
            if (hidden && down && !was_down && distance >= trigger) {
                if (!visible(true)) break;
                hidden = false; deadline = 0;
            }
            was_down = down;
            if (!hidden && distance < trigger) {
                if (!visible(false)) break;
                hidden = true; deadline = 0;
            } else if (hidden) {
                if (distance > height) {
                    if (!deadline) deadline = now() + debounce;
                    if (now() >= deadline) {
                        if (!visible(true)) break;
                        hidden = false; deadline = 0;
                    }
                } else deadline = 0;
            }
        }
        struct timespec interval = {.tv_nsec = 16000000};
        nanosleep(&interval, NULL);
    }
    // Restore even if interrupted while an animation was starting.
    char *restore[] = {(char *)bar, "--bar", "hidden=off", "y_offset=0", NULL};
    command(restore);
    if (lock_fd >= 0) close(lock_fd);
    return 0;
}
