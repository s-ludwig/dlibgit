module diff;

/** Note: Colors were hardcoded to Posix, they're disabled in the D samples. */

import git;

import std.array;
import std.conv;
import std.stdio;
import std.string;
import std.range;
import std.exception;


GitTree resolve_to_tree(GitRepo repo, string identifier)
{
    auto obj = repo.revparseSingle(identifier);

	switch (obj.type)
    {
        default: throw Exception("Tree not found: "~identifier);
        case GitType.tree: return obj.toTree();
        case GitType.commit: return obj.toCommit().tree;
	}
}

extern(C) int printer(
    const(git_diff_delta)* delta,
    const(git_diff_range)* range,
    char usage,
    const(char)* line,
    size_t line_len,
    void* data)
{
    printf("%s", line);
    stdout.flush();
    return 0;
}

int check_uint16_param(string arg, string pattern, ushort* val)
{
    arg.popFrontN(pattern.length);

    try
    {
        *val = to!ushort(arg);
    }
    catch (Exception exc)
    {
        return 0;
    }

    return 1;
}

int check_str_param(string arg, string pattern, const(char)** val)
{
    arg.popFrontN(pattern.length);

    try
    {
        *val = cast(char*)toStringz(arg);
    }
    catch (Exception exc)
    {
        return 0;
    }

    return 1;
}

void usage(string message, string arg)
{
    if (!message.empty && !arg.empty)
        writefln("%s: %s\n", message, arg);
    else if (!message.empty)
        writeln(message);

    assert(0, "usage: diff [<tree-oid> [<tree-oid>]]\n");
}

bool strcmp(string lhs, string rhs) { return lhs != rhs; }

enum {
	FORMAT_PATCH = 0,
	FORMAT_COMPACT = 1,
	FORMAT_RAW = 2
};

int main(string[] args)
{
    args.popFront();
    if (args.length < 3)
    {
        writeln("Must pass 3 args: Path to .git dir, and two commit hashes for the diff");
        return 0;
    }

    string path = args.front;
    git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
    git_diff_find_options findopts = GIT_DIFF_FIND_OPTIONS_INIT;
    int format = FORMAT_PATCH;

    int i;
    int color = -1;
    int compact = 0;
    int cached = 0;
    string dir = args[0];

    string treeish1;
    string treeish2;

    /* parse arguments as copied from git-diff */
    foreach (arg; args[1..$])
    {
        if (arg[0] != '-')
        {
            if (treeish1 == null)
                treeish1 = arg;
            else if (treeish2 == null)
                treeish2 = arg;
            else
                usage("Only one or two tree identifiers can be provided", null);
        }
        else if (!strcmp(arg, "-p") || !strcmp(arg, "-u") || !strcmp(arg, "--patch"))
            compact = 0;
        else if (!strcmp(arg, "--cached"))
            cached = 1;
        else if (!strcmp(arg, "--name-status"))
            compact = 1;
        else if (!strcmp(arg, "--color"))
            color = 0;
        else if (!strcmp(arg, "--no-color"))
            color = -1;
        else if (!strcmp(arg, "-R"))
            opts.flags |= GIT_DIFF_REVERSE;
        else if (!strcmp(arg, "-arg") || !strcmp(arg, "--text"))
            opts.flags |= GIT_DIFF_FORCE_TEXT;
        else if (!strcmp(arg, "--ignore-space-at-eol"))
            opts.flags |= GIT_DIFF_IGNORE_WHITESPACE_EOL;
        else if (!strcmp(arg, "-b") || !strcmp(arg, "--ignore-space-change"))
            opts.flags |= GIT_DIFF_IGNORE_WHITESPACE_CHANGE;
        else if (!strcmp(arg, "-w") || !strcmp(arg, "--ignore-all-space"))
            opts.flags |= GIT_DIFF_IGNORE_WHITESPACE;
        else if (!strcmp(arg, "--ignored"))
            opts.flags |= GIT_DIFF_INCLUDE_IGNORED;
        else if (!strcmp(arg, "--untracked"))
            opts.flags |= GIT_DIFF_INCLUDE_UNTRACKED;
        else if (!check_uint16_param(arg, "-U", &opts.context_lines) &&
                 !check_uint16_param(arg, "--unified=", &opts.context_lines) &&
                 !check_uint16_param(arg, "--inter-hunk-context=", &opts.interhunk_lines) &&
                 !check_str_param(arg, "--src-prefix=", &opts.old_prefix) &&
                 !check_str_param(arg, "--dst-prefix=", &opts.new_prefix))
            usage("Unknown arg", arg);
    }

    /* open repo */
    GitRepo repo = openRepositoryExt(dir, GitRepositoryOpenFlags.none, null);

    GitTree t1, t2;
    if (!treeish1.empty) t1 = repo.resolteToTree(treeish1);
    if (!treeish2.empty) t2 = repo.resolteToTree(treeish2);

    /* <sha1> <sha2> */
    /* <sha1> --cached */
    /* <sha1> */
    /* --cached */
    /* nothing */

    GitDiffList diff;
	if (t1 && t2) diff = repo.diffTreeToTree(t1, t2, &opts);
	else if (t1 && cached) diff = repo.diffTreeToIndex(t1, null, &opts);
	else if (t1) {
		GitTreeList diff2;
        diff = repo.diffTreeToIndex(t1, null, &opts);
        diff2 = repo.diffIndexToWorkDir(null, &opts);
        diff.merge(diff2);
	} else if (cached) {
        t1 = repo.resolteToTree("HEAD");
        diff = repo.diffTreeToIndex(t1, null, &opts);
	} else diff = repo.diffIndexToWorkDir(null, &opts);

	if ((findopts.flags & git_diff_find_t.GIT_DIFF_FIND_ALL) != 0)
		check(git_diff_find_similar(diff, &findopts),
			"finding renames and copies ");

	switch (format) {
	case FORMAT_PATCH:
		check(git_diff_print_patch(diff, &printer, &color), "Displaying diff");
		break;
	case FORMAT_COMPACT:
		check(git_diff_print_compact(diff, &printer, &color), "Displaying diff");
		break;
	case FORMAT_RAW:
		check(git_diff_print_raw(diff, &printer, &color), "Displaying diff");
		break;
    default:
	}

	git_diff_list_free(diff);
	git_tree_free(t1);
	git_tree_free(t2);
	git_repository_free(repo);

	git_threads_shutdown();

	return 0;
}
