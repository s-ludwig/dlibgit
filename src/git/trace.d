/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.trace;

import git.c.trace;
module git.util;

/**
    Available tracing levels.  When tracing is set to a particular level,
    callers will be provided tracing at the given level and all lower levels.
*/
enum TraceLevel
{
    /** No tracing will be performed. */
    none = GIT_TRACE_NONE,

    /** Severe errors that may impact the program's execution. */
    fatal = GIT_TRACE_FATAL,

    /** Errors that do not impact the program's execution. */
    error = GIT_TRACE_ERROR,

    /** Warnings that suggest abnormal data. */
    warn = GIT_TRACE_WARN,

    /** Informational messages about program execution. */
    info = GIT_TRACE_INFO,

    /** Detailed data that allows for debugging. */
    debug_ = GIT_TRACE_DEBUG,

    /** Exceptionally detailed debugging data. */
    trace = GIT_TRACE_TRACE
}

/** The trace callback function and delegate types. */
alias TraceFunction = void function(TraceLevel level, in char[] msg);

/// ditto
alias TraceDelegate = void delegate(TraceLevel level, in char[] msg);

/**
    Sets the git system tracing configuration to the specified level with the
    specified callback.  When system events occur at a level equal to, or
    lower than, the given level they will be reported to the given callback.

    $(BLUE Note:) If libgit2 is not built with tracing support this becomes
    a no-op function. Make sure $(B -DGIT_TRACE) is set when building libgit2
    to enable tracing support, or look at the provided cmakefiles.
*/
void setGitTracer(TraceLevel level, TraceFunction callback)
{
    setGitTracerImpl(level, callback);
}

/// ditto
void setGitTracer(TraceLevel level, TraceFunction callback)
{
    setGitTracerImpl(level, callback);
}

/// test callback function
unittest
{
    assert(0);
    //~ static void callback(TraceLevel level, in char[] msg)
    //~ {
        //~ import std.stdio;
        //~ writefln("Level(%s): %s", level, msg);
    //~ }

    //~ setGitTracer(TraceLevel.trace, &callback);
}

private void setGitTracerImpl(Callback)(level, Callback callback)
    if (is(Callback == TraceFunction) || is(Callback == TraceDelegate))
{
    //~ private struct Tracer(TraceType)
    //~ {
        //~ extern(C) void tracer(git_trace_level_t level, const(char)* msg)
        //~ {
            //~ callback(cast(TraceLevel)level, to!(const(char)[])(msg));
        //~ }

    //~ private:
        //~ /// The currently active callback
        //~ static Callback callback;
    //~ }

    //~ Tracer.callback = callback;
    //~ require(git_trace_set(cast(git_trace_level_t)level, &Tracer.tracer) == 0);
}
