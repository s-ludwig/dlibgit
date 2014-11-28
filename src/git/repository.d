/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.repository;

import core.exception;

import std.algorithm;
import std.conv;
import std.exception;
import std.file;
import std.path;
import std.process;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;
import std.typetuple;

import deimos.git2.common;
import deimos.git2.errors;
import deimos.git2.ignore;
import deimos.git2.oid;
import deimos.git2.repository;
import deimos.git2.types;
import deimos.git2.branch;

import git.common;
import git.exception;
import git.index;
import git.oid;
import git.reference;
import git.types;
import git.util;
import git.version_;
import deimos.git2.refs;
import deimos.git2.strarray;

version(unittest)
{
    enum _baseTestDir = "test";
    enum _testRepo = "test/repo/.git";
    string _userRepo = buildPath(_baseTestDir, "_myTestRepo");
}


GitRepo openRepository(string path)
{
    git_repository* dst;
    require(git_repository_open(&dst, path.gitStr) == 0);
    return GitRepo(dst);
}

GitRepo openRepositoryExt(string path, GitRepositoryOpenFlags flags, string ceiling_dirs)
{
    git_repository* dst;
    require(git_repository_open_ext(&dst, path.gitStr, flags, ceiling_dirs.gitStr) == 0);
    return GitRepo(dst);
}

GitRepo openBareRepository(string bare_path)
{
    git_repository* dst;
    require(git_repository_open_bare(&dst, bare_path.toStringz()) == 0);
    return GitRepo(dst);
}

/**
    Create a new Git repository in the given folder.

    Parameters:

    $(D path): the path to the git repository.

    $(D openBare): if equal to $(D OpenBare.yes), a Git
    repository without a working directory is created at the
    pointed path.

    If equal to $(D OpenBare.no), the provided path will be
    considered as the working directory into which the .git
    directory will be created.
*/
GitRepo initRepository(in char[] path, OpenBare openBare)
{
    git_repository* repo;
    require(git_repository_init(&repo, path.gitStr, cast(bool)openBare) == 0);
    return GitRepo(repo);
}
alias initRepo = initRepository;

///
unittest
{
    // create a bare test repository and ensure the HEAD file exists
    auto repo = initRepo(_userRepo, OpenBare.yes);
    scope(exit) rmdirRecurse(_userRepo);
    assert(buildPath(_userRepo, "HEAD").exists);
}

///
unittest
{
    // create a non-bare test repository and ensure the .git/HEAD file exists
    auto repo = initRepo(_userRepo, OpenBare.no);
    scope(exit) rmdirRecurse(_userRepo);
    assert(buildPath(_userRepo, ".git/HEAD").exists);
}

GitRepo initRepository(string path, GitRepositoryInitOptions options)
{
    git_repository* ret;
    git_repository_init_options copts;
    copts.flags = cast(git_repository_init_flag_t)options.flags;
    copts.mode = cast(git_repository_init_mode_t)options.mode;
    copts.workdir_path = options.workdirPath.gitStr;
    copts.description = options.description.gitStr;
    copts.template_path = options.templatePath.gitStr;
    copts.initial_head = options.initialHead.gitStr;
    copts.origin_url = options.originURL.gitStr;
    require(git_repository_init_ext(&ret, path.toStringz(), &copts) == 0);
    return GitRepo(ret);
}

/**
    Discover a git repository and return its path if found.

    The lookup starts from $(D startPath) and continues searching across
    parent directories. The lookup stops when one of the following
    becomes true:

    $(LI a git repository is found.)
    $(LI a directory referenced in $(D ceilingDirs) has been reached.)
    $(LI the filesystem changed (if acrossFS is equal to $(D AcrossFS.no).))

    Parameters:

    $(D startPath): The base path where the lookup starts.

    $(D ceilingDirs): An array of absolute paths which are symbolic-link-free.
    If any of these paths are reached a $(D GitException) will be thrown.

    $(D acrossFS): If equal to $(D AcrossFS.yes) the lookup will
    continue when a filesystem device change is detected while exploring
    parent directories, otherwise $(D GitException) is thrown.

    $(B Note:) The lookup always performs on $(D startPath) even if
    $(D startPath) is listed in $(D ceilingDirs).
 */
string discoverRepo(in char[] startPath, string[] ceilingDirs = null, AcrossFS acrossFS = AcrossFS.yes)
{
    char[MaxGitPathLen] buffer;
    const c_ceilDirs = ceilingDirs.join(GitPathSep).gitStr;

    version(assert)
    {
        foreach (path; ceilingDirs)
            assert(path.isAbsolute, format("Error: Path in ceilingDirs is not absolute: '%s'", path));
    }

    require(git_repository_discover(buffer.ptr, buffer.length, startPath.gitStr, cast(bool)acrossFS, c_ceilDirs) == 0);

    return to!string(buffer.ptr);
}

///
unittest
{
    /**
        look for the .git repo in "test/repo/a/".
        The .git directory will be found one dir up, and will
        contain the line 'gitdir: ../../.git/modules/test/repo'.
        The function will expand this line and return the true
        repository location.
    */
    string path = buildPath(_testRepo.dirName, "a");
    string repoPath = discoverRepo(path);
    assert(repoPath.relativePath.toPosixPath == ".git/modules/test/repo");

    // verify the repo can be opened
    auto repo = openRepository(repoPath);
}

///
unittest
{
    // ceiling dir is found before any git repository
    string path = buildPath(_testRepo.dirName, "a");
    string[] ceils = [_testRepo.dirName.absolutePath.buildNormalizedPath];
    assertThrown!GitException(discoverRepo(path, ceils));
}

///
unittest
{
    // all ceiling paths must be absolute
    string[] ceils = ["../.."];
    assertThrown!AssertError(discoverRepo(_testRepo.dirName, ceils));
}


/**
    The structure representing a git repository.
*/
struct GitRepo
{
    /// Default-construction is disabled
    //@disable this();

    ///
    unittest
    {
        //static assert(!__traits(compiles, GitRepo()));
    }

    // internal
    package this(git_repository* payload)
    {
        _data = Data(payload);
    }

    /**
        Open a git repository.

        Parameters:

        $(D path) must either be a path to the .git directory or
        the base path of the .git directory.

        If $(D path) does not exist or if the .git directory is not
        found in $(D path), a $(D GitException) is thrown.
     */
    deprecated("Please use openRepository instead.") this(in char[] path)
    {
        git_repository* repo;
        require(git_repository_open(&repo, path.gitStr) == 0);
        _data = Data(repo);
    }

    ///
    unittest
    {
        // throw when path does not exist
        assertThrown!GitException(openRepository(r".\invalid\path\.git"));

        // open using the path of the .git directory
        auto repo1 = openRepository(_testRepo);

        // open using the base path of the .git directory
        auto repo2 = openRepository(_testRepo.dirName);
    }

    @property GitReference head()
    {
        git_reference* ret;
        require(git_repository_head(&ret, this.cHandle) == 0);
        return GitReference(this, ret);
    }

    /**
        Check if this repository's HEAD is detached.

        A repository's HEAD is detached when it
        points directly to a commit instead of a branch.
    */
    @property bool isHeadDetached()
    {
        return requireBool(git_repository_head_detached(_data._payload));
    }

    ///
    unittest
    {
        // by default test repo's HEAD is pointing to a commit
        auto repo1 = openRepository(_testRepo);
        assert(repo1.isHeadDetached);

        // new repo does not have a detached head
        auto repo2 = initRepo(_userRepo, OpenBare.no);
        scope(exit) rmdirRecurse(_userRepo);
        assert(!repo2.isHeadDetached);
    }

    /**
        Check if the current branch is an orphan.

        An orphan branch is one named from HEAD but which doesn't exist in
        the refs namespace, because it doesn't have any commit to point to.
    */
    @property bool isHeadOrphan()
    {
        static if (targetLibGitVersion == VersionInfo(0, 19, 0)) {
            return requireBool(git_repository_head_orphan(_data._payload));
        } else {
            return requireBool(git_repository_head_unborn(_data._payload));
        }
    }

    ///
    unittest
    {
        auto repo1 = openRepository(_testRepo);
        assert(!repo1.isHeadOrphan);

        // new repo has orphan branch
        auto repo2 = initRepo(_userRepo, OpenBare.no);
        scope(exit) rmdirRecurse(_userRepo);
        assert(repo2.isHeadOrphan);
    }

    /**
        Check if this repository is empty.

        An empty repository is one which has just been
        initialized and contains no references.
    */
    @property bool isEmpty()
    {
        return requireBool(git_repository_is_empty(_data._payload));
    }

    ///
    unittest
    {
        // existing repo is non-empty
        auto repo1 = openRepository(_testRepo);
        assert(!repo1.isEmpty);

        // new repo is empty
        auto repo2 = initRepo(_userRepo, OpenBare.no);
        scope(exit) rmdirRecurse(_userRepo);
        assert(repo2.isEmpty);
    }

    /**
        Check if this repository is a bare repository.
    */
    @property bool isBare()
    {
        return requireBool(git_repository_is_bare(_data._payload));
    }

    ///
    unittest
    {
        // existing repo is not bare
        auto repo = openRepository(_testRepo);
        assert(!repo.isBare);
    }

    ///
    unittest
    {
        // new bare repo is bare
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);
        assert(repo.isBare);
    }

    ///
    unittest
    {
        // new non-bare repo is not bare
        auto repo = initRepo(_userRepo, OpenBare.no);
        scope(exit) rmdirRecurse(_userRepo);
        assert(!repo.isBare);
    }

    /**
        Get the path of this repository.

        This is the path of the `.git` folder for normal repositories,
        or of the repository itself for bare repositories.

        $(B Note:) Submodule repositories will have their path set
        by the $(B gitdir) option in the `.git` file.
    */
    @property string path()
    {
        return to!string(git_repository_path(_data._payload));
    }

    ///
    unittest
    {
        // existing repo path
        auto repo = openRepository(_testRepo);
        assert(repo.path.relativePath.toPosixPath == ".git/modules/test/repo");
    }

    ///
    unittest
    {
        // new bare repo path is the path of the repo itself
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);
        assert(repo.path.relativePath.toPosixPath == "test/_myTestRepo");
    }

    ///
    unittest
    {
        // new non-bare repo path is the path of the .git directory
        auto repo = initRepo(_userRepo, OpenBare.no);
        scope(exit) rmdirRecurse(_userRepo);
        assert(repo.path.relativePath.toPosixPath == "test/_myTestRepo/.git");
    }

    /**
        Get the path of the working directory of this repository.

        If the repository is bare, this function will return $(D null).

        $(B Note): Unlike $(D path), this function is not affected
        by whether this repository is a submodule of another repository.
    */
    @property string workPath()
    {
        return to!string(git_repository_workdir(_data._payload));
    }

    ///
    unittest
    {
        // existing repo work path is different to the path of the .git directory,
        // since this repo is a submodule
        auto repo = openRepository(_testRepo);
        assert(repo.workPath.relativePath.toPosixPath == "test/repo");
    }

    ///
    unittest
    {
        // new bare repo work path is empty
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);
        assert(repo.workPath.relativePath.toPosixPath is null);
    }

    ///
    unittest
    {
        // new non-bare repo work path is by default the directory path of the .git directory
        auto repo = initRepo(_userRepo, OpenBare.no);
        scope(exit) rmdirRecurse(_userRepo);
        assert(repo.workPath.relativePath.toPosixPath == "test/_myTestRepo");
    }

    /**
        Set the work path of this repository.

        The work path doesn't need to be the same one
        that contains the `.git` folder for this repository.

        If this repository is bare, setting its work path
        will turn it into a normal repository capable of performing
        all the common workdir operations (checkout, status, index
        manipulation, etc).

        If $(D updateGitlink) equals $(D UpdateGitlink.yes), gitlink
        will be created or updated in the work path. Additionally if
        the work path is not the parent of the $(B .git) directory
        the $(B core.worktree) option will be set in the configuration.
    */
    void setWorkPath(in char[] newWorkPath, UpdateGitlink updateGitlink = UpdateGitlink.no)
    {
        require(git_repository_set_workdir(_data._payload, newWorkPath.gitStr, cast(int)updateGitlink) == 0);
    }

    ///
    unittest
    {
        // new bare repo work path is empty
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);
        assert(repo.workPath.relativePath.toPosixPath is null);
        assert(repo.isBare);

        // set a new work path for the bare repo, verify it's set, and also
        // verify repo is no longer a bare repo
        repo.setWorkPath(_testRepo);
        assert(repo.workPath.relativePath.toPosixPath == _testRepo);
        assert(!repo.isBare);
    }

    @property GitIndex index()
    {
        git_index* dst;
        require(git_repository_index(&dst, this.cHandle) == 0);
        return GitIndex(this, dst);
    }

    /**
        Check if the merge message file exists for this repository.
    */
    @property bool mergeMsgExists()
    {
        auto result = git_repository_message(null, 0, _data._payload);

        if (result == GIT_ENOTFOUND)
            return false;

        require(result >= 0);
        return true;
    }

    ///
    unittest
    {
        // write a merge message file and verify it can be read
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);
        assert(!repo.mergeMsgExists);

        string msgPath = buildPath(repo.path, "MERGE_MSG");
        std.file.write(msgPath, "");
        assert(repo.mergeMsgExists);
        assert(repo.mergeMsg !is null && repo.mergeMsg.length == 0);
    }

    /**
        Retrieve the merge message for this repository.

        Operations such as git revert/cherry-pick/merge with the -n option
        stop just short of creating a commit with the changes and save
        their prepared message in .git/MERGE_MSG so the next git-commit
        execution can present it to the user for them to amend if they
        wish.

        Use this function to get the contents of this file.

        $(B Note:) Remember to remove the merge message file after you
        create the commit, by calling $(D removeMergeMsg).
        Use $(D mergeMsgExists) if you want to explicitly check for the
        existence of the merge message file.

        $(B Note:) This function returns an empty string when the message
        file is empty, but returns $(D null) if the message file cannot be found.
    */
    @property string mergeMsg()
    {
        char[MaxGitPathLen] buffer;
        auto result = git_repository_message(buffer.ptr, buffer.length, _data._payload);

        if (result == GIT_ENOTFOUND)
            return null;

        require(result >= 0);

        string msg = to!string(buffer.ptr);
        if (msg is null)
            msg = "";  // null signals a missing file

        return msg;
    }

    ///
    unittest
    {
        // write a merge message file and verify it can be read
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string msgPath = buildPath(repo.path, "MERGE_MSG");

        string msg = "merge this";
        std.file.write(msgPath, msg);
        assert(repo.mergeMsg == msg);

        msg = "";
        std.file.write(msgPath, msg);
        assert(repo.mergeMsg !is null && repo.mergeMsg == msg);
    }

    /**
        Remove the merge message file for this repository.
        If the message file does not exist $(D GitException) is thrown.
        Use $(D mergeMsgExists) to check whether the merge message
        file exists.
    */
    void removeMergeMsg()
    {
        require(git_repository_message_remove(_data._payload) == 0);
    }

    ///
    unittest
    {
        // write a merge message file and verify it can be read
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string msgPath = buildPath(repo.path, "MERGE_MSG");
        string msg = "merge this";
        std.file.write(msgPath, msg);

        assert(repo.mergeMsg == msg);

        // verify removal of merge message
        repo.removeMergeMsg();
        assert(repo.mergeMsg is null);

        // verify throwing when removing file which doesn't exist
        assertThrown!GitException(repo.removeMergeMsg());
    }

    /**
        Call the $(D callback) function for each entry in the $(B FETCH_HEAD) file in this repository.

        The $(D callback) type must be either $(D FetchHeadFunction) or $(D FetchHeadDelegate).

        This function will return when either all entries are exhausted or when the $(D callback)
        returns $(D ContinueWalk.no).
    */
    void walkFetchHead(FetchHeadFunction callback)
    {
        walkFetchHeadImpl(callback);
    }

    /// ditto
    void walkFetchHead(scope FetchHeadDelegate callback)
    {
        walkFetchHeadImpl(callback);
    }

    /// Walk the $(B FETCH_HEAD) file with a function.
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string[] fetchHeadItems = [
            "23c3c6add8162693f85b3b41c9bf6550a71a57d3		branch 'master' of git://github.com/D-Programming-Language/dmd\n",
            "aaf64112624abab1f6cc8f610223f6e12b525e09		branch 'master' of git://github.com/D-Programming-Language/dmd\n"
        ];

        std.file.write(buildPath(repo.path, "FETCH_HEAD"), fetchHeadItems.join());

        static ContinueWalk walkFunc(in char[] refName, in char[] remoteURL, GitOid oid, bool isMerge)
        {
            static int count;
            count++;

            assert(count != 2);  // we're stopping after the first iteration

            assert(refName == "refs/heads/master");
            assert(remoteURL == "git://github.com/D-Programming-Language/dmd");
            assert(oid == GitOid("23C3C6ADD8162693F85B3B41C9BF6550A71A57D3"));

            return ContinueWalk.no;
        }

        repo.walkFetchHead(&walkFunc);
    }

    /// Walk the $(B FETCH_HEAD) file with a delegate.
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string[] fetchHeadItems = [
            "23c3c6add8162693f85b3b41c9bf6550a71a57d3		branch 'master' of git://github.com/D-Programming-Language/dmd\n",
            "aaf64112624abab1f6cc8f610223f6e12b525e09		branch 'master' of git://github.com/D-Programming-Language/dmd\n"
        ];

        std.file.write(buildPath(repo.path, "FETCH_HEAD"), fetchHeadItems.join());

        struct S
        {
            size_t count;

            // delegate walker
            ContinueWalk walker(in char[] refName, in char[] remoteURL, GitOid oid, bool isMerge)
            {
                string line = fetchHeadItems[count++];
                string commitHex = line.split[0];

                assert(refName == "refs/heads/master");
                assert(remoteURL == "git://github.com/D-Programming-Language/dmd");
                assert(oid == GitOid(commitHex));

                return ContinueWalk.yes;
            }

            ~this()
            {
                assert(count == 2);  // verify we've walked through all the items
            }
        }

        S s;
        repo.walkFetchHead(&s.walker);
    }

    /** Walk the $(B FETCH_HEAD) file in a foreach loop. */
    auto walkFetchHead()
    {
        static struct S
        {
            GitRepo repo;

            int opApply(int delegate(in char[] refName, in char[] remoteURL, GitOid oid, bool isMerge) dg)
            {
                repo.walkFetchHeadImpl(dg);
                return 1;
            }
        }

        return S(this);
    }

    /// Walk the $(B FETCH_HEAD) using a foreach loop.
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string[] fetchHeadItems = [
            "23c3c6add8162693f85b3b41c9bf6550a71a57d3		branch 'master' of git://github.com/D-Programming-Language/dmd\n",
            "aaf64112624abab1f6cc8f610223f6e12b525e09		branch 'master' of git://github.com/D-Programming-Language/dmd\n"
        ];

        std.file.write(buildPath(repo.path, "FETCH_HEAD"), fetchHeadItems.join());

        size_t count;
        foreach (refName, remoteURL, oid, isMerge; repo.walkFetchHead)
        {
            string line = fetchHeadItems[count++];
            string commitHex = line.split[0];

            assert(refName == "refs/heads/master");
            assert(remoteURL == "git://github.com/D-Programming-Language/dmd");
            assert(oid == GitOid(commitHex));
        }

        // ensure we've iterated all itmes
        assert(count == 2);

        count = 0;
        foreach (refName, remoteURL, oid, isMerge; repo.walkFetchHead)
        {
            string line = fetchHeadItems[count++];
            string commitHex = line.split[0];

            assert(refName == "refs/heads/master");
            assert(remoteURL == "git://github.com/D-Programming-Language/dmd");
            assert(oid == GitOid(commitHex));
            break;
        }

        // ensure 'break' works
        assert(count == 1);
    }

    private void walkFetchHeadImpl(Callback)(Callback callback)
        if (is(Callback == FetchHeadFunction) || is(Callback == FetchHeadDelegate) || is(Callback == FetchHeadOpApply))
    {
        // return 1 to stop iteration
        static extern(C) int c_callback(
            const(char)* refName,
            const(char)* remoteURL,
            const(git_oid)* oid,
            uint isMerge,
            void *payload)
        {
            Callback callback = *cast(Callback*)payload;

            auto result = callback(toSlice(refName), toSlice(remoteURL), GitOid(*oid), isMerge == 1);

            static if (is(Callback == FetchHeadOpApply))
                return result;
            else
                return result == ContinueWalk.no;
        }

        auto result = git_repository_fetchhead_foreach(_data._payload, &c_callback, &callback);
        require(result == GIT_EUSER || result == 0);
    }

    /**
        Return the list of items in the $(B FETCH_HEAD) file as
        an array of $(D FetchHeadItem)'s.
    */
    FetchHeadItem[] getFetchHeadItems()
    {
        auto buffer = appender!(typeof(return));
        getFetchHeadItems(buffer);
        return buffer.data;
    }

    ///
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string[] fetchHeadItems = [
            "23c3c6add8162693f85b3b41c9bf6550a71a57d3		branch 'master' of git://github.com/D-Programming-Language/dmd\n",
            "aaf64112624abab1f6cc8f610223f6e12b525e09		branch 'master' of git://github.com/D-Programming-Language/dmd\n"
        ];

        std.file.write(buildPath(repo.path, "FETCH_HEAD"), fetchHeadItems.join());

        foreach (string line, FetchHeadItem item; lockstep(fetchHeadItems, repo.getFetchHeadItems()))
        {
            string commitHex = line.split[0];

            assert(item.refName == "refs/heads/master");
            assert(item.remoteURL == "git://github.com/D-Programming-Language/dmd");
            assert(item.oid == GitOid(commitHex));
        }
    }

    /**
        Read each item in the $(B FETCH_HEAD) file to
        the output range $(D sink), and return the $(D sink).
    */
    Range getFetchHeadItems(Range)(Range sink)
        if (isOutputRange!(Range, FetchHeadItem))
    {
        alias Params = ParameterTypeTuple!FetchHeadFunction;
        walkFetchHead( (Params params) { sink.put(FetchHeadItem(params)); return ContinueWalk.yes; } );
        return sink;
    }

    ///
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string[] fetchHeadItems = [
            "23c3c6add8162693f85b3b41c9bf6550a71a57d3		branch 'master' of git://github.com/D-Programming-Language/dmd\n",
            "aaf64112624abab1f6cc8f610223f6e12b525e09		branch 'master' of git://github.com/D-Programming-Language/dmd\n"
        ];

        std.file.write(buildPath(repo.path, "FETCH_HEAD"), fetchHeadItems.join());

        auto buffer = repo.getFetchHeadItems(appender!(FetchHeadItem[]));

        foreach (string line, FetchHeadItem item; lockstep(fetchHeadItems, buffer.data))
        {
            string commitHex = line.split[0];

            assert(item.refName == "refs/heads/master");
            assert(item.remoteURL == "git://github.com/D-Programming-Language/dmd");
            assert(item.oid == GitOid(commitHex));
        }
    }

    /**
        Call the $(D callback) function for each entry in the $(B MERGE_HEAD) file in this repository.

        The $(D callback) type must be either $(D MergeHeadFunction) or $(D MergeHeadDelegate).

        This function will return when either all entries are exhausted or when the $(D callback)
        returns $(D ContinueWalk.no).
    */
    void walkMergeHead(MergeHeadFunction callback)
    {
        walkMergeHeadImpl(callback);
    }

    /// ditto
    void walkMergeHead(scope MergeHeadDelegate callback)
    {
        walkMergeHeadImpl(callback);
    }

    /// Walk the $(B MERGE_HEAD) file with a function.
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string[] mergeHeadItems = [
            "e496660174425e3147a0593ced2954f3ddbf65ca\n",
            "e496660174425e3147a0593ced2954f3ddbf65ca\n"
        ];

        std.file.write(buildPath(repo.path, "MERGE_HEAD"), mergeHeadItems.join());

        static ContinueWalk walkFunc(GitOid oid)
        {
            static int count;
            count++;

            assert(count != 2);  // we're stopping after the first iteration

            assert(oid == GitOid("e496660174425e3147a0593ced2954f3ddbf65ca"));

            return ContinueWalk.no;
        }

        repo.walkMergeHead(&walkFunc);
    }

    /// Walk the $(B MERGE_HEAD) file with a delegate.
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string[] mergeHeadItems = [
            "e496660174425e3147a0593ced2954f3ddbf65ca\n",
            "e496660174425e3147a0593ced2954f3ddbf65ca\n"
        ];

        std.file.write(buildPath(repo.path, "MERGE_HEAD"), mergeHeadItems.join());

        struct S
        {
            size_t count;

            // delegate walker
            ContinueWalk walker(GitOid oid)
            {
                string line = mergeHeadItems[count++];
                string commitHex = line.split[0];
                assert(oid == GitOid(commitHex));

                return ContinueWalk.yes;
            }

            ~this()
            {
                assert(count == 2);  // verify we've walked through all the items
            }
        }

        S s;
        repo.walkMergeHead(&s.walker);
    }

    /** Walk the $(B MERGE_HEAD) file in a foreach loop. */
    auto walkMergeHead()
    {
        static struct S
        {
            GitRepo repo;

            int opApply(int delegate(GitOid oid) dg)
            {
                repo.walkMergeHeadImpl(dg);
                return 1;
            }
        }

        return S(this);
    }

    /// Walk the $(B MERGE_HEAD) using a foreach loop.
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string[] mergeHeadItems = [
            "e496660174425e3147a0593ced2954f3ddbf65ca\n",
            "e496660174425e3147a0593ced2954f3ddbf65ca\n"
        ];

        std.file.write(buildPath(repo.path, "MERGE_HEAD"), mergeHeadItems.join());

        size_t count;
        foreach (oid; repo.walkMergeHead)
        {
            string line = mergeHeadItems[count++];
            string commitHex = line.split[0];
            assert(oid == GitOid(commitHex));
        }

        // ensure we've iterated all itmes
        assert(count == 2);

        count = 0;
        foreach (oid; repo.walkMergeHead)
        {
            string line = mergeHeadItems[count++];
            string commitHex = line.split[0];
            assert(oid == GitOid(commitHex));
            break;
        }

        // ensure 'break' works
        assert(count == 1);
    }

    private void walkMergeHeadImpl(Callback)(Callback callback)
        if (is(Callback == MergeHeadFunction) || is(Callback == MergeHeadDelegate) || is(Callback == MergeHeadOpApply))
    {
        static extern(C) int c_callback(const(git_oid)* oid, void* payload)
        {
            Callback callback = *cast(Callback*)payload;

            // return < 0 to stop iteration. Bug in v0.19.0
            // 0.20.0 and later requires just != 0, so -1 is fine there, too
            // https://github.com/libgit2/libgit2/issues/1703
            static if (is(Callback == MergeHeadOpApply))
                return callback(GitOid(*oid)) ? -1 : 0;
            else
                return callback(GitOid(*oid)) == ContinueWalk.no ? -1 : 0;
        }

        auto result = git_repository_mergehead_foreach(_data._payload, &c_callback, &callback);
        require(result == GIT_EUSER || result == 0);
    }

    /**
        Return the list of items in the $(B MERGE_HEAD) file as
        an array of $(D MergeHeadItem)'s.
    */
    MergeHeadItem[] getMergeHeadItems()
    {
        auto buffer = appender!(typeof(return));
        getMergeHeadItems(buffer);
        return buffer.data;
    }

    ///
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string[] mergeHeadItems = [
            "e496660174425e3147a0593ced2954f3ddbf65ca\n",
            "e496660174425e3147a0593ced2954f3ddbf65ca\n"
        ];

        std.file.write(buildPath(repo.path, "MERGE_HEAD"), mergeHeadItems.join());

        foreach (string line, MergeHeadItem item; lockstep(mergeHeadItems, repo.getMergeHeadItems()))
        {
            string commitHex = line.split[0];
            assert(item.oid == GitOid(commitHex));
        }
    }

    /**
        Read each item in the $(B MERGE_HEAD) file to
        the output range $(D sink), and return the $(D sink).
    */
    Range getMergeHeadItems(Range)(Range sink)
        if (isOutputRange!(Range, MergeHeadItem))
    {
        alias Params = ParameterTypeTuple!MergeHeadFunction;
        walkMergeHead( (Params params) { sink.put(MergeHeadItem(params)); return ContinueWalk.yes; } );
        return sink;
    }

    ///
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string[] mergeHeadItems = [
            "e496660174425e3147a0593ced2954f3ddbf65ca\n",
            "e496660174425e3147a0593ced2954f3ddbf65ca\n"
        ];

        std.file.write(buildPath(repo.path, "MERGE_HEAD"), mergeHeadItems.join());

        auto buffer = repo.getMergeHeadItems(appender!(MergeHeadItem[]));

        foreach (string line, MergeHeadItem item; lockstep(mergeHeadItems, buffer.data))
        {
            string commitHex = line.split[0];
            assert(item.oid == GitOid(commitHex));
        }
    }

    /**
        Return the current state this repository,
        e.g. whether an operation such as merge is in progress.
    */
    @property RepoState state()
    {
        return to!RepoState(git_repository_state(_data._payload));
    }

    ///
    unittest
    {
        // todo: test all states
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);
        assert(repo.state == RepoState.none);
    }

    /** Get the currently active namespace for this repository. */
    @property string namespace()
    {
        return to!string(git_repository_get_namespace(_data._payload));
    }

    ///
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);
        assert(repo.namespace is null);
    }

    /**
        Set the active namespace for this repository.

        This namespace affects all reference operations for the repo.
        See $(B man gitnamespaces).

        The namespace should not include the refs folder,
        e.g. to namespace all references under $(B refs/namespaces/foo/)
        use $(B foo) as the namespace.
    */
    @property void namespace(in char[] nspace)
    {
        require(git_repository_set_namespace(_data._payload, nspace.gitStr) == 0);
    }

    ///
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);
        repo.namespace = "foobar";
        assert(repo.namespace == "foobar");
    }

    /** Determine if this repository is a shallow clone. */
    @property bool isShallow()
    {
        return git_repository_is_shallow(_data._payload) == 1;
    }

    ///
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);
        assert(!repo.isShallow);
    }

    /**
        Remove all the metadata associated with an ongoing git merge,
        including MERGE_HEAD, MERGE_MSG, etc.
    */
    void cleanupMerge()
    {
        require(git_repository_merge_cleanup(_data._payload) == 0);
    }

    ///
    unittest
    {
        // write a merge message file
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string msgPath = buildPath(repo.path, "MERGE_MSG");
        string msg = "merge this";
        std.file.write(msgPath, msg);

        assert(repo.mergeMsg == msg);

        // verify removal of merge message
        repo.cleanupMerge();
        assert(repo.mergeMsg is null);

        // verify throwing when removing file which doesn't exist
        assertThrown!GitException(repo.removeMergeMsg());
    }

    /**
        Calculate hash of file using repository filtering rules.

        If you simply want to calculate the hash of a file on disk with no filters,
        you can use the global $(D hashFile) function. However, if you want to
        hash a file in the repository and you want to apply filtering rules (e.g.
        $(B crlf) filters) before generating the SHA, then use this function.

        Parameters:

        $(D path): Path to file on disk whose contents should be hashed.
                   This can be a relative path.

        $(D type): The object type to hash the file as (e.g. $(D GitType.blob))

        $(D asPath): The path to use to look up filtering rules.
                     If this is $(D null), then the $(D path) parameter will be
                     used instead. If this is passed as the empty string, then no
                     filters will be applied when calculating the hash.
    */
    GitOid hashFile(in char[] path, GitType type, in char[] asPath = null)
    {
        git_oid _git_oid;

        require(git_repository_hashfile(&_git_oid, _data._payload, path.gitStr, cast(git_otype)type, asPath.gitStr) == 0);

        return GitOid(_git_oid);
    }

    ///
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        string objPath = buildPath(repo.path, "test.d");
        string text = "import std.stdio;";
        std.file.write(objPath, text);

        auto oid = repo.hashFile(objPath, GitType.blob);
    }

    /**
        Make the repository HEAD point to the specified reference.

        If the provided reference points to a Tree or a Blob, the HEAD is
        unaltered and -1 is returned.

        If the provided reference points to a branch, the HEAD will point
        to that branch, staying attached, or become attached if it isn't yet.
        If the branch doesn't exist yet, no error will be return. The HEAD
        will then be attached to an unborn branch.

        Otherwise, the HEAD will be detached and will directly point to
        the Commit.

        @param repo Repository pointer
        @param refname Canonical name of the reference the HEAD should point at
        @return 0 on success, or an error code
    */
    // todo: add overload that takes an actual reference, and then call .toname
    version(none)  // todo: implement when commit, blob, and refs APIs are in place
    void setHead(in char[] refName)
    {
        require(git_repository_set_head(_data._payload, refName.gitStr) == 0);
    }

    ///
    version(none)  // todo: implement when commit, blob, and refs APIs are in place
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.no);

        scope(exit)
        {
            // workaround for Issue 10529:
            // http://d.puremagic.com/issues/show_bug.cgi?id=10529
            version(Windows)
                executeShell(format("rmdir /q /s %s", _userRepo.absolutePath.buildNormalizedPath));
            else
                rmdirRecurse(_userRepo);
        }

        // create a blob file in the work path
        string blobPath = buildPath(repo.workPath, "foo.text");
        std.file.write(blobPath, "blob");

        import deimos.git2.blob;
        git_oid _oid;
        require(0 == git_blob_create_fromworkdir(&_oid, repo._data._payload, "/foo.text"));

        import deimos.git2.refs;
        git_reference* ptr;
        require(0 == git_reference_create(&ptr, repo._data._payload, "MY_REF", &_oid, false));

        repo.setHead("MY_REF");
    }

    /**
     * Sets the repository's HEAD to the given commit object id.
     *
     * When successful, the HEAD will be in a detached state.
     *
     * If the provided oid is not found or cannot be resolved to a commit,
     * the repository is left unaltered and an exception is thrown.
     */
    void setHeadDetached(const(GitOid) oid) {
        require(git_repository_set_head_detached(_data._payload, &oid._get_oid()) == 0);
    }

    /**
     * Detach the HEAD.
     *
     * If the HEAD is already detached and points to a Commit, 0 is returned.
     *
     * If the HEAD is already detached and points to a Tag, the HEAD is
     * updated into making it point to the peeled Commit, and 0 is returned.
     *
     * If the HEAD is already detached and points to a non-commit oid, the HEAD is
     * unaltered, and -1 is returned.
     *
     * Otherwise, the HEAD will be detached and point to the peeled Commit.
     *
     * @param repo Repository pointer
     * @return 0 on success, GIT_EORPHANEDHEAD when HEAD points to a non existing
     * branch or an error code
     */
    //~ int git_repository_detach_head(
            //~ git_repository* repo);

    /**
        Add one or more ignore rules to this repository.

        Excludesfile rules (i.e. .gitignore rules) are generally read from
        .gitignore files in the repository tree, or from a shared system file
        only if a $(B core.excludesfile) config value is set.  The library also
        keeps a set of per-repository internal ignores that can be configured
        in-memory and will not persist. This function allows you to add to
        that internal rules list.
    */
    void addIgnoreRules(scope const(char)[][] rules...)
    {
        require(git_ignore_add_rule(_data._payload, rules.join("\n").gitStr) == 0);
    }

    ///
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.no);
        repo.addIgnoreRules("/foo");
        repo.addIgnoreRules(["/foo", "/bar"]);
    }

    /**
        Clear ignore rules that were explicitly added.

        Resets to the default internal ignore rules.  This will not turn off
        rules in .gitignore files that actually exist in the filesystem.

        The default internal ignores ignore ".", ".." and ".git" entries.
    */
    void clearIgnoreRules()
    {
        require(git_ignore_clear_internal_rules(_data._payload) == 0);
    }

    ///
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.no);
        repo.addIgnoreRules("/foo");
        repo.addIgnoreRules(["/foo", "/bar"]);
        repo.clearIgnoreRules();
    }

    /**
        Test if the ignore rules apply to a given path.

        This function checks the ignore rules to see if they would apply to the
        given file.  This indicates if the file would be ignored regardless of
        whether the file is already in the index or committed to the repository.

        One way to think of this is if you were to do "git add ." on the
        directory containing the file, would it be added or not?
    */
    bool isPathIgnored(in char[] path)
    {
        int ignored;
        require(git_ignore_path_is_ignored(&ignored, _data._payload, path.gitStr) == 0);
        return ignored == 1;
    }

    ///
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.no);
        assert(!repo.isPathIgnored("/foo"));

        repo.addIgnoreRules("/foo");
        assert(repo.isPathIgnored("/foo"));

        repo.addIgnoreRules(["/foo", "/bar"]);
        assert(repo.isPathIgnored("/bar"));

        repo.clearIgnoreRules();
        assert(!repo.isPathIgnored("/foo"));
        assert(!repo.isPathIgnored("/bar"));
    }

    mixin RefCountedGitObject!(git_repository, git_repository_free);
}


enum GitRepositoryOpenFlags {
	none = 0,
    noSearch = GIT_REPOSITORY_OPEN_NO_SEARCH,
    crossFS = GIT_REPOSITORY_OPEN_CROSS_FS,
    //bare = GIT_REPOSITORY_OPEN_BARE // available in 0.20.0
}

enum GitRepositoryInitMode {
    sharedUmask = GIT_REPOSITORY_INIT_SHARED_UMASK,
    sharedGroup = GIT_REPOSITORY_INIT_SHARED_GROUP,
    sharedAll = GIT_REPOSITORY_INIT_SHARED_ALL,
}

enum GitRepositoryInitFlags {
    none = 0,
    bare = GIT_REPOSITORY_INIT_BARE,
    reinit = GIT_REPOSITORY_INIT_NO_REINIT,
    noDotGitDir = GIT_REPOSITORY_INIT_NO_DOTGIT_DIR,
    makeDir = GIT_REPOSITORY_INIT_MKDIR,
    makePath = GIT_REPOSITORY_INIT_MKPATH,
    externalTemplate = GIT_REPOSITORY_INIT_EXTERNAL_TEMPLATE
}

struct GitRepositoryInitOptions {
    GitRepositoryInitFlags flags;
    GitRepositoryInitMode mode;
    string workdirPath;
    string description;
    string templatePath;
    string initialHead;
    string originURL;
}


/// Used to specify whether to continue search on a file system change.
enum UpdateGitlink
{
    /// Stop searching on file system change.
    no,

    /// Continue searching on file system change.
    yes
}

/** A single item in the list of the $(B FETCH_HEAD) file. */
struct FetchHeadItem
{
    ///
    const(char)[] refName;

    ///
    const(char)[] remoteURL;

    ///
    GitOid oid;

    ///
    bool isMerge;
}

/// The function or delegate type that $(D walkFetchHead) can take as the callback.
alias FetchHeadFunction = ContinueWalk function(in char[] refName, in char[] remoteURL, GitOid oid, bool isMerge);

/// ditto
alias FetchHeadDelegate = ContinueWalk delegate(in char[] refName, in char[] remoteURL, GitOid oid, bool isMerge);

/// ditto
alias FetchHeadOpApply = int delegate(in char[] refName, in char[] remoteURL, GitOid oid, bool isMerge);

/** A single item in the list of the $(B MERGE_HEAD) file. */
struct MergeHeadItem
{
    GitOid oid;
}

/// The function or delegate type that $(D walkMergeHead) can take as the callback.
alias MergeHeadFunction = ContinueWalk function(GitOid oid);

/// ditto
alias MergeHeadDelegate = ContinueWalk delegate(GitOid oid);

/// ditto
alias MergeHeadOpApply = int delegate(GitOid oid);

/// The various states a repository can be in.
enum RepoState
{
    none, ///
    merge, ///
    revert, ///
    cherry_pick, ///
    bisect, ///
    rebase, ///
    rebase_interactive, ///
    rebase_merge, ///
    apply_mailbox, ///
    apply_mailbox_or_rebase, ///
}


/// Used to specify whether to continue search on a file system change.
enum AcrossFS
{
    /// Stop searching on file system change.
    no,

    /// Continue searching on file system change.
    yes
}


/// Used to specify whether to open a bare repository
enum OpenBare
{
    /// Open a non-bare repository
    no,

    /// Open a bare repository
    yes
}


version(none):

/**
    TODO: Functions to wrap later:
*/

// todo: wrap git_odb before wrapping this function
int git_repository_wrap_odb(git_repository **out_, git_odb *odb);

// todo: when git_config is ported
int git_repository_config(git_config **out_, git_repository *repo);

// todo: when git_odb is ported
int git_repository_odb(git_odb **out_, git_repository *repo);

// todo: when git_refdb is ported
int git_repository_refdb(git_refdb **out_, git_repository *repo);

