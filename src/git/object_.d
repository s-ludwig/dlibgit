module git.object_;

import git.oid;
import git.repository;
import git.types;
import git.util;

import deimos.git2.object_;
import deimos.git2.types;

// Note: This file includes none of the original comments, as they might
// be copyrightable material.

///
struct GitObject
{
    // Internal, see free-standing constructor functions below.
    package this(GitRepo repo, git_object* obj)
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
    @property inout(GitRepo) owner() inout { return _repo; }

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

    mixin RefCountedGitObject!(git_object, git_object_free);
    // Reference to the parent repository to keep it alive.
    private GitRepo _repo;
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
