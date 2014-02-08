/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git;

public
{
    import git.attribute;
    import git.checkout;
    import git.clone;
    import git.common;
    import git.config;
    import git.credentials;
    import git.exception;
    import git.object_;
    import git.oid;
    import git.remote;
    import git.repository;
    import git.trace;
    import git.transport;
    import git.types;
    import git.version_;
}

private
{
    import git.c;
    import git.util;
}
