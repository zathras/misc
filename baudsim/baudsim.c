

#include <sys/timeb.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>



static struct timeb start_time;

static int get_ms() {
    struct timeb now;
    int diff;

    ftime(&now);
    diff = (int) (now.time - start_time.time);
    diff *= 1000;
    diff += now.millitm;
    diff -= start_time.millitm;
    return diff;
}

/*
 * Super cheesy, but simple:  I just sleep for one millisecond.
 * At least I'm not busy-waiting!
 */
static void pause() {
    struct timespec sleep_time;
    sleep_time.tv_sec = 0;
    sleep_time.tv_nsec = 1 * 1000 * 1000;
    nanosleep(&sleep_time, NULL);
}

int main(int argc, char** argv) {
    int c;
    int chars;
    int last_ms;
    int baud;

    ftime(&start_time);
    if (argc != 2 || sscanf(argv[1], "%d", &baud) != 1) {
        fprintf(stderr, "Usage:  baudsim <baud>\n");
        exit(1);
    }
    chars = 0;
    last_ms = get_ms();

    while ((c = getchar()) != -1) {
        int this_ms;

        putchar(c);
        this_ms = get_ms();
        if (this_ms - last_ms > 100) {
            chars = 0;
            ftime(&start_time);
            last_ms = get_ms();
        } else {
            chars++;
            /* Overflow?  Yeah, but with 32 bit ints, we'd have to run
             * for two months for that to happen.  Not worth doing properly
             * for this hack.
             */
            while (chars > this_ms * baud  / 10000) {
                pause();
                this_ms = get_ms();
            }
        }
        fflush(stdout);
    }
    printf("\nbaudsim terminates.\n");
    return 0;
}



