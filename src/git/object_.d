module git.object_;

import git.oid;
import git.repository;
import git.types;
import git.util;

import git2.object_;
import git2.types;

// Note: This file includes none of the original comments, as they might
// be copyrightable material.

///
struct GitObject
{
    // Internal, see free-standing constructor functions below.
    private this(GitRepo repo, git_object* obj)
    {
        _repo = repo;
        _data = Data(obj);
    }

    ///
    @property GitOid id()
    {
        return GitOid(*git_object_id(_data._payload));
    }

    ///
    @property GitType type()
    {
        return cast(GitType)git_object_type(_data._payload);
    }

    ///
    @property GitRepo owner()
    {
        return GitRepo(git_object_owner(_data._payload));
    }

    ///
    @property GitObject dup()
    {
        git_object* result;
        require(git_object_dup(&result, _data._payload) == 0);
        return GitObject(_repo, result);
    }

    ///
    @property GitObject peel(GitType targetType)
    {
        git_object* result;
        require(git_object_peel(&result, _data._payload, cast(git_otype)targetType) == 0);
        return GitObject(_repo, result);
    }

package:
    /**
     * The internal libgit2 handle for this object.
     *
     * Care should be taken not to escape the reference outside a scope where
     * a GitObject encapsulating the handle is kept alive.
     */
    @property git_object* cHandle()
    {
        return _data._payload;
    }

private:
    struct Payload
    {
        this(git_object* payload)
        {
            _payload = payload;
        }

        ~this()
        {
            if (_payload !is null)
            {
                git_object_free(_payload);
                _payload = null;
            }
        }

        /// Should never perform copy
        @disable this(this);

        /// Should never perform assign
        @disable void opAssign(typeof(this));

        git_object* _payload;
    }

    // Reference to the parent repository to keep it alive.
    GitRepo _repo;

    import std.typecons : RefCounted, RefCountedAutoInitialize;
    alias RefCounted!(Payload, RefCountedAutoInitialize.no) Data;
    Data _data;
}

///
GitObject lookup(GitRepo repo, GitOid oid, GitType type = GitType.any)
{
    git_object* result;
    auto cOid = oid._get_oid;
    require(git_object_lookup(&result, repo.cHandle, &cOid, cast(git_otype)type) == 0);
    return GitObject(repo, result);
}

///
GitObject lookupByPrefix(GitRepo repo, GitOid oid, size_t prefixLen, GitType type = GitType.any)
{
    git_object* result;
    auto cOid = oid._get_oid;
    require(git_object_lookup(&result, repo.cHandle, &cOid, cast(git_otype)type) == 0);
    return GitObject(repo, result);
}

///
GitObject lookup(GitRepo repo, in char[] hexString, GitType type = GitType.any)
{
    auto oid = GitOid(hexString);
    if (hexString.length < GitOid.MaxHexSize)
    {
        return lookupByPrefix(repo, oid, hexString.length, type);
    }
    else
    {
        return lookup(repo, oid, type);
    }
}

///
const(char)[] toString(GitType type)
{
    return git_object_type2string(cast(git_otype)type).toSlice;
}

///
GitType toType(in char[] str)
{
    return cast(GitType)git_object_string2type(str.gitStr);
}

///
bool isLoose(GitType type)
{
    return git_object_typeisloose(cast(git_otype)type) != 0;
}

/+
extern (C):
size_t git_object__size(git_otype type);
+/
