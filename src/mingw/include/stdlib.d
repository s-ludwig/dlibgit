module mingw.include.stdlib;

import core.stdc.config;

alias extern(C) int function() _onexit_t;

struct div_t 
{
    int quot;
    int rem;
}

struct ldiv_t 
{
    c_long quot;
    c_long rem;
}

struct lldiv_t 
{
    long quot;
    long rem;
}
