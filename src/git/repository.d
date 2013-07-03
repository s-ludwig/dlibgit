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
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;
import std.typetuple;

import git.c.common;
import git.c.errors;
import git.c.oid;
import git.c.repository;
import git.c.types;

import git.common;
import git.exception;
import git.oid;
import git.types;
import git.util;

version(unittest)
{
    enum _baseTestDir = "../test";
    enum _testRepo = "../test/repo/.git";
    string _userRepo = buildPath(_baseTestDir, "_myTestRepo");
}

/// Used to specify whether to continue search on a file system change.
enum UpdateGitlink
{
    /// Stop searching on file system change.
    no,

    /// Continue searching on file system change.
    yes
}

/// The return type of a callback used in e.g. the $(D walkFetchHead) function.
enum ContinueWalk
{
    /// Stop walk
    no,

    /// Continue walk
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

/** A single item in the list of the $(B MERGE_HEAD) file. */
struct MergeHeadItem
{
    GitOid oid;
}

/// The function or delegate type that $(D walkMergeHead) can take as the callback.
alias MergeHeadFunction = ContinueWalk function(GitOid oid);

/// ditto
alias MergeHeadDelegate = ContinueWalk delegate(GitOid oid);

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

/**
    The structure representing a git repository.
*/
struct GitRepo
{
    /// Default-construction is disabled
    @disable this();

    ///
    unittest
    {
        static assert(!__traits(compiles, GitRepo()));
    }

    // internal
    private this(git_repository* payload)
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
    this(in char[] path)
    {
        _data = Data(path);
    }

    ///
    unittest
    {
        // throw when path does not exist
        assertThrown!GitException(GitRepo(r".\invalid\path\.git"));

        // open using the path of the .git directory
        auto repo1 = GitRepo(_testRepo);

        // open using the base path of the .git directory
        auto repo2 = GitRepo(_testRepo.dirName);
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
        auto repo1 = GitRepo(_testRepo);
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
        return requireBool(git_repository_head_orphan(_data._payload));
    }

    ///
    unittest
    {
        auto repo1 = GitRepo(_testRepo);
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
        auto repo1 = GitRepo(_testRepo);
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
        auto repo = GitRepo(_testRepo);
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
        auto repo = GitRepo(_testRepo);
        assert(repo.path.relativePath.toPosixPath == "../.git/modules/test/repo");
    }

    ///
    unittest
    {
        // new bare repo path is the path of the repo itself
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);
        assert(repo.path.relativePath.toPosixPath == "../test/_myTestRepo");
    }

    ///
    unittest
    {
        // new non-bare repo path is the path of the .git directory
        auto repo = initRepo(_userRepo, OpenBare.no);
        scope(exit) rmdirRecurse(_userRepo);
        assert(repo.path.relativePath.toPosixPath == "../test/_myTestRepo/.git");
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
        auto repo = GitRepo(_testRepo);
        assert(repo.workPath.relativePath.toPosixPath == "../test/repo");
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
        assert(repo.workPath.relativePath.toPosixPath == "../test/_myTestRepo");
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
        require(git_repository_set_workdir(_data._payload, newWorkPath.toStringz, cast(int)updateGitlink) == 0);
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
        repo.setWorkPath("../test");
        assert(repo.workPath.relativePath.toPosixPath == "../test");
        assert(!repo.isBare);
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
        char[4096] buffer;
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

    private void walkFetchHeadImpl(Callback)(Callback callback)
        if (is(Callback == FetchHeadFunction) || is(Callback == FetchHeadDelegate))
    {
        static extern(C) int c_callback(
            const(char)* refName,
            const(char)* remoteURL,
            const(git_oid)* oid,
            uint isMerge,
            void *payload)
        {
            alias toSlice = to!(const(char)[]);
            Callback callback = *cast(Callback*)payload;

            // return 1 to stop iteration
            return callback(toSlice(refName), toSlice(remoteURL), GitOid(*oid), isMerge == 1) == ContinueWalk.no;
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

    ///
    unittest
    {
        auto repo = initRepo(_userRepo, OpenBare.yes);
        scope(exit) rmdirRecurse(_userRepo);

        static ContinueWalk walkFunc(GitOid oid)
        {
            import std.stdio;
            writefln("Function walking - oid: %s", oid);
            return ContinueWalk.no;
        }

        static assert(__traits(compiles, repo.walkMergeHead(&walkFunc) ));

        int x;

        ContinueWalk walkDelegate(GitOid oid)
        {
            x++;  // make it a delegate
            import std.stdio;
            writefln("Delegate walking - oid: %s", oid);
            return ContinueWalk.yes;
        }

        static assert(__traits(compiles, repo.walkMergeHead(&walkDelegate) ));
    }

    private void walkMergeHeadImpl(Callback)(Callback callback)
        if (is(Callback == MergeHeadFunction) || is(Callback == MergeHeadDelegate))
    {
        static extern(C) int c_callback(const(git_oid)* oid, void* payload)
        {
            Callback callback = *cast(Callback*)payload;

            // return 1 to stop iteration
            return callback(GitOid(*oid)) == ContinueWalk.no;
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
        static assert(__traits(compiles, repo.getMergeHeadItems() ));
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
        static assert(__traits(compiles, repo.getMergeHeadItems(appender!(MergeHeadItem[])) ));
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
        require(git_repository_set_namespace(_data._payload, nspace.toStringz) == 0);
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

        require(git_repository_hashfile(&_git_oid, _data._payload, path.toStringz, cast(git_otype)type, asPath.toStringz) == 0);

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
     * Make the repository HEAD point to the specified reference.
     *
     * If the provided reference points to a Tree or a Blob, the HEAD is
     * unaltered and -1 is returned.
     *
     * If the provided reference points to a branch, the HEAD will point
     * to that branch, staying attached, or become attached if it isn't yet.
     * If the branch doesn't exist yet, no error will be return. The HEAD
     * will then be attached to an unborn branch.
     *
     * Otherwise, the HEAD will be detached and will directly point to
     * the Commit.
     *
     * @param repo Repository pointer
     * @param refname Canonical name of the reference the HEAD should point at
     * @return 0 on success, or an error code
     */
    // todo: add overload that takes an actual reference, and then call .toname
    // on it once references are ported
    //~ int git_repository_set_head(
            //~ git_repository* repo,
            //~ const(char)* refname);

    /**
     * Make the repository HEAD directly point to the Commit.
     *
     * If the provided commit_oid cannot be found in the repository, the HEAD
     * is unaltered and GIT_ENOTFOUND is returned.
     *
     * If the provided commit_oid cannot be peeled into a commit, the HEAD
     * is unaltered and -1 is returned.
     *
     * Otherwise, the HEAD will eventually be detached and will directly point to
     * the peeled Commit.
     *
     * @param repo Repository pointer
     * @param commit_oid Object id of the Commit the HEAD should point to
     * @return 0 on success, or an error code
     */
    //~ int git_repository_set_head_detached(
            //~ git_repository* repo,
            //~ const(git_oid)* commit_oid);

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

private:

    /** Payload for the $(D git_repository) object which should be refcounted. */
    struct Payload
    {
        this(git_repository* payload)
        {
            _payload = payload;
        }

        this(in char[] path)
        {
            require(git_repository_open(&_payload, path.toStringz) == 0);
        }

        ~this()
        {
            //~ writefln("- %s", __FUNCTION__);

            if (_payload !is null)
            {
                git_repository_free(_payload);
                _payload = null;
            }
        }

        /// Should never perform copy
        @disable this(this);

        /// Should never perform assign
        @disable void opAssign(typeof(this));

        git_repository* _payload;
    }

    // refcounted git_oid_shorten
    alias RefCounted!(Payload, RefCountedAutoInitialize.no) Data;
    Data _data;
}

/// Used to specify whether to continue search on a file system change.
enum AcrossFS
{
    /// Stop searching on file system change.
    no,

    /// Continue searching on file system change.
    yes
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
    char[4096] buffer;
    const c_ceilDirs = ceilingDirs.join(GitPathSep).toStringz;

    version(assert)
    {
        foreach (path; ceilingDirs)
            assert(path.isAbsolute, format("Error: Path in ceilingDirs is not absolute: '%s'", path));
    }

    require(git_repository_discover(buffer.ptr, buffer.length, startPath.toStringz, cast(bool)acrossFS, c_ceilDirs) == 0);

    return to!string(buffer.ptr);
}

///
unittest
{
    /**
        look for the .git repo in "../test/repo/a/".
        The .git directory will be found one dir up, and will
        contain the line 'gitdir: ../../.git/modules/test/repo'.
        The function will expand this line and return the true
        repository location.
    */
    string path = buildPath(_testRepo.dirName, "a");
    string repoPath = discoverRepo(path);
    assert(repoPath.relativePath.toPosixPath == "../.git/modules/test/repo");

    // verify the repo can be opened
    auto repo = GitRepo(repoPath);
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

/// Used to specify whether to open a bare repository
enum OpenBare
{
    /// Open a non-bare repository
    no,

    /// Open a bare repository
    yes
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
GitRepo initRepo(in char[] path, OpenBare openBare)
{
    git_repository* repo;
    require(git_repository_init(&repo, path.toStringz, cast(bool)openBare) == 0);
    return GitRepo(repo);
}

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

extern (C):

/**
    TODO: Functions to wrap later:
*/


// todo: complicated init option
/**
 * Option flags for `git_repository_init_ext`.
 *
 * These flags configure extra behaviors to `git_repository_init_ext`.
 * In every case, the default behavior is the zero value (i.e. flag is
 * not set).  Just OR the flag values together for the `flags` parameter
 * when initializing a new repo.  Details of individual values are:
 *
 * * BARE   - Create a bare repository with no working directory.
 * * NO_REINIT - Return an EEXISTS error if the repo_path appears to
 *        already be an git repository.
 * * NO_DOTGIT_DIR - Normally a "/.git/" will be appended to the repo
 *        path for non-bare repos (if it is not already there), but
 *        passing this flag prevents that behavior.
 * * MKDIR  - Make the repo_path (and workdir_path) as needed.  Init is
 *        always willing to create the ".git" directory even without this
 *        flag.  This flag tells init to create the trailing component of
 *        the repo and workdir paths as needed.
 * * MKPATH - Recursively make all components of the repo and workdir
 *        paths as necessary.
 * * EXTERNAL_TEMPLATE - libgit2 normally uses internal templates to
 *        initialize a new repo.  This flags enables external templates,
 *        looking the "template_path" from the options if set, or the
 *        `init.templatedir` global config if not, or falling back on
 *        "/usr/share/git-core/templates" if it exists.
 */
//~ enum git_repository_init_flag_t {
        //~ GIT_REPOSITORY_INIT_BARE              = (1u << 0),
        //~ GIT_REPOSITORY_INIT_NO_REINIT         = (1u << 1),
        //~ GIT_REPOSITORY_INIT_NO_DOTGIT_DIR     = (1u << 2),
        //~ GIT_REPOSITORY_INIT_MKDIR             = (1u << 3),
        //~ GIT_REPOSITORY_INIT_MKPATH            = (1u << 4),
        //~ GIT_REPOSITORY_INIT_EXTERNAL_TEMPLATE = (1u << 5),
//~ } ;

//~ mixin _ExportEnumMembers!git_repository_init_flag_t;

/**
 * Mode options for `git_repository_init_ext`.
 *
 * Set the mode field of the `git_repository_init_options` structure
 * either to the custom mode that you would like, or to one of the
 * following modes:
 *
 * * SHARED_UMASK - Use permissions configured by umask - the default.
 * * SHARED_GROUP - Use "--shared=group" behavior, chmod'ing the new repo
 *        to be group writable and "g+sx" for sticky group assignment.
 * * SHARED_ALL - Use "--shared=all" behavior, adding world readability.
 * * Anything else - Set to custom value.
 */
//~ enum git_repository_init_mode_t {
        //~ GIT_REPOSITORY_INIT_SHARED_UMASK = octal!0,
        //~ GIT_REPOSITORY_INIT_SHARED_GROUP = octal!2775,
        //~ GIT_REPOSITORY_INIT_SHARED_ALL   = octal!2777,
//~ } ;

//~ mixin _ExportEnumMembers!git_repository_init_mode_t;

/**
 * Extended options structure for `git_repository_init_ext`.
 *
 * This contains extra options for `git_repository_init_ext` that enable
 * additional initialization features.  The fields are:
 *
 * * flags - Combination of GIT_REPOSITORY_INIT flags above.
 * * mode  - Set to one of the standard GIT_REPOSITORY_INIT_SHARED_...
 *        constants above, or to a custom value that you would like.
 * * workdir_path - The path to the working dir or NULL for default (i.e.
 *        repo_path parent on non-bare repos).  IF THIS IS RELATIVE PATH,
 *        IT WILL BE EVALUATED RELATIVE TO THE REPO_PATH.  If this is not
 *        the "natural" working directory, a .git gitlink file will be
 *        created here linking to the repo_path.
 * * description - If set, this will be used to initialize the "description"
 *        file in the repository, instead of using the template content.
 * * template_path - When GIT_REPOSITORY_INIT_EXTERNAL_TEMPLATE is set,
 *        this contains the path to use for the template directory.  If
 *        this is NULL, the config or default directory options will be
 *        used instead.
 * * initial_head - The name of the head to point HEAD at.  If NULL, then
 *        this will be treated as "master" and the HEAD ref will be set
 *        to "refs/heads/master".  If this begins with "refs/" it will be
 *        used verbatim; otherwise "refs/heads/" will be prefixed.
 * * origin_url - If this is non-NULL, then after the rest of the
 *        repository initialization is completed, an "origin" remote
 *        will be added pointing to this URL.
 */
struct git_repository_init_options {
        uint version_;
        uint32_t    flags;
        uint32_t    mode;
        const(char)* workdir_path;
        const(char)* description;
        const(char)* template_path;
        const(char)* initial_head;
        const(char)* origin_url;
} ;

enum GIT_REPOSITORY_INIT_OPTIONS_VERSION = 1;
enum git_repository_init_options GIT_REPOSITORY_INIT_OPTIONS_INIT = { GIT_REPOSITORY_INIT_OPTIONS_VERSION };

/**
 * Create a new Git repository in the given folder with extended controls.
 *
 * This will initialize a new git repository (creating the repo_path
 * if requested by flags) and working directory as needed.  It will
 * auto-detect the case sensitivity of the file system and if the
 * file system supports file mode bits correctly.
 *
 * @param out Pointer to the repo which will be created or reinitialized.
 * @param repo_path The path to the repository.
 * @param opts Pointer to git_repository_init_options struct.
 * @return 0 or an error code on failure.
 */
int git_repository_init_ext(
        git_repository **out_,
        const(char)* repo_path,
        git_repository_init_options *opts);

/**
 * Create a "fake" repository to wrap an object database
 *
 * Create a repository object to wrap an object database to be used
 * with the API when all you have is an object database. This doesn't
 * have any paths associated with it, so use with care.
 *
 * @param out pointer to the repo
 * @param odb the object database to wrap
 * @return 0 or an error code
 */
// todo: wrap git_odb before wrapping this function
int git_repository_wrap_odb(git_repository **out_, git_odb *odb);

/**
 * Open a bare repository on the serverside.
 *
 * This is a fast open for bare repositories that will come in handy
 * if you're e.g. hosting git repositories and need to access them
 * efficiently
 *
 * @param out Pointer to the repo which will be opened.
 * @param bare_path Direct path to the bare repository
 * @return 0 on success, or an error code
 */
// todo: when we figure out on which dirs we can open this
int git_repository_open_bare(git_repository **out_, const(char)* bare_path);

/**
 * Retrieve and resolve the reference pointed at by HEAD.
 *
 * The returned `git_reference` will be owned by caller and
 * `git_reference_free()` must be called when done with it to release the
 * allocated memory and prevent a leak.
 *
 * @param out pointer to the reference which will be retrieved
 * @param repo a repository object
 *
 * @return 0 on success, GIT_EORPHANEDHEAD when HEAD points to a non existing
 * branch, GIT_ENOTFOUND when HEAD is missing; an error code otherwise
 */
// todo: when git_reference is ported
int git_repository_head(git_reference **out_, git_repository *repo);


/**
 * Get the configuration file for this repository.
 *
 * If a configuration file has not been set, the default
 * config set for the repository will be returned, including
 * global and system configurations (if they are available).
 *
 * The configuration file must be freed once it's no longer
 * being used by the user.
 *
 * @param out Pointer to store the loaded config file
 * @param repo A repository object
 * @return 0, or an error code
 */
// todo: when git_config is ported
int git_repository_config(git_config **out_, git_repository *repo);

/**
 * Get the Object Database for this repository.
 *
 * If a custom ODB has not been set, the default
 * database for the repository will be returned (the one
 * located in `.git/objects`).
 *
 * The ODB must be freed once it's no longer being used by
 * the user.
 *
 * @param out Pointer to store the loaded ODB
 * @param repo A repository object
 * @return 0, or an error code
 */
// todo: when git_odb is ported
int git_repository_odb(git_odb **out_, git_repository *repo);

/**
 * Get the Reference Database Backend for this repository.
 *
 * If a custom refsdb has not been set, the default database for
 * the repository will be returned (the one that manipulates loose
 * and packed references in the `.git` directory).
 *
 * The refdb must be freed once it's no longer being used by
 * the user.
 *
 * @param out Pointer to store the loaded refdb
 * @param repo A repository object
 * @return 0, or an error code
 */
// todo: when git_refdb is ported
int git_repository_refdb(git_refdb **out_, git_repository *repo);

/**
 * Get the Index file for this repository.
 *
 * If a custom index has not been set, the default
 * index for the repository will be returned (the one
 * located in `.git/index`).
 *
 * The index must be freed once it's no longer being used by
 * the user.
 *
 * @param out Pointer to store the loaded index
 * @param repo A repository object
 * @return 0, or an error code
 */
// todo: when git_index is ported
int git_repository_index(git_index **out_, git_repository *repo);
