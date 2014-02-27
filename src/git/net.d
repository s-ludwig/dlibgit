/*
 *             Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.net;

import git.oid;

import deimos.git2.net;

import std.conv;


struct GitRemoteHead {
    package this(in git_remote_head* h)
    {
        this.local = h.local != 0;
        this.oid = GitOid(h.oid);
        this.localOid = GitOid(h.loid);
        this.name = h.name.to!string();
    }

    bool local;
    GitOid oid;
    GitOid localOid;
    string name;
}
