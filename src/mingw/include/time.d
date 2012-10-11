module mingw.include.time;

import core.stdc.config;

alias c_long __time32_t;
alias long __time64_t;
alias c_long clock_t;
alias __time32_t time_t;

struct tm 
{
    int tm_sec;
    int tm_min;
    int tm_hour;
    int tm_mday;
    int tm_mon;
    int tm_year;
    int tm_wday;
    int tm_yday;
    int tm_isdst;
}
