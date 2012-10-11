module diff;

/*
    Colors were hardcoded to Posix, they're disabled here.
*/

import git2.blob;
import git2._object;
import git2.index;
import git2.commit;
import git2.refs;
import git2.tree;
import git2.errors;
import git2.repository;
import git2.types;
import git2.oid;
import git2.diff;

import std.array;
import std.conv;
import std.stdio;
import std.string;
import std.range;
import std.exception;

void check(int error, const char* message)
{
    enforce(!error, format("%s (%s)\n", to!string(message), error));
}

int resolve_to_tree(git_repository* repo, string identifier, git_tree** tree)
{
    int err     = 0;
    size_t  len = identifier.length;
    git_oid oid;
    git_object* obj = null;

    /* try to resolve as OID */
    if (git_oid_fromstrn(&oid, toStringz(identifier), len) == 0)
        git_object_lookup_prefix(&obj, repo, &oid, len, git_otype.GIT_OBJ_ANY);

    /* try to resolve as reference */
    if (obj == null)
    {
        git_reference* _ref;
        git_reference* resolved;

        if (git_reference_lookup(&_ref, repo, toStringz(identifier)) == 0)
        {
            git_reference_resolve(&resolved, _ref);
            git_reference_free(_ref);

            if (resolved)
            {
                git_object_lookup(&obj, repo, git_reference_oid(resolved), git_otype.GIT_OBJ_ANY);
                git_reference_free(resolved);
            }
        }
    }

    if (obj == null)
        return GIT_ENOTFOUND;

    switch (git_object_type(obj))
    {
        case git_otype.GIT_OBJ_TREE:
            *tree = cast(git_tree*)obj;
            break;

        case git_otype.GIT_OBJ_COMMIT:
            err = git_commit_tree(tree, cast(git_commit*)obj);
            git_object_free(obj);
            break;

        default:
            err = GIT_ENOTFOUND;
    }

    return err;
}

string[] colors = [
    "\033[m",                /* reset */
    "\033[1m",               /* bold */
    "\033[31m",              /* red */
    "\033[32m",              /* green */
    "\033[36m"               /* cyan */
];

extern(C) int printer(
    void* data,
    const(git_diff_delta)* delta,
    const(git_diff_range)* range,
    char usage,
    const(char)* line,
    size_t line_len)
{
    int* last_color = cast(int*)data;
    int color = 0;

    if (*last_color >= 0)
    {
        switch (usage)
        {
            case GIT_DIFF_LINE_ADDITION:
                color = 3;
                break;

            case GIT_DIFF_LINE_DELETION:
                color = 2;
                break;

            case GIT_DIFF_LINE_ADD_EOFNL:
                color = 3;
                break;

            case GIT_DIFF_LINE_DEL_EOFNL:
                color = 2;
                break;

            case GIT_DIFF_LINE_FILE_HDR:
                color = 1;
                break;

            case GIT_DIFF_LINE_HUNK_HDR:
                color = 4;
                break;

            default:
                color = 0;
        }

        //~ if (color != *last_color)
        //~ {
            //~ if (*last_color == 1 || color == 1)
                //~ fputs(colors[0], stdout);
            //~ fputs(colors[color], stdout);
            //~ *last_color = color;
        //~ }
    }

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

int check_str_param(string arg, string pattern, char** val)
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

int main(string[] args)
{
    args.popFront();
    if (args.length < 3)
    {
        writeln("Must pass 3 args: Path to .git dir, and two commit hashes for the diff");
        return 0;
    }
    
    string path = args.front;
    git_repository* repo;
    git_tree* t1, t2;
    git_diff_options opts;
    git_diff_list* diff;
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
    check(git_repository_open_ext(&repo, toStringz(dir), 0, null), "Could not open repository");

    if (!treeish1.empty)
        check(resolve_to_tree(repo, treeish1, &t1), "Looking up first tree");
    
    if (!treeish2.empty)
        check(resolve_to_tree(repo, treeish2, &t2), "Looking up second tree");

    /* <sha1> <sha2> */
    /* <sha1> --cached */
    /* <sha1> */
    /* --cached */
    /* nothing */

    if (t1 && t2)
        check(git_diff_tree_to_tree(repo, &opts, t1, t2, &diff), "Diff");
    else if (t1 && cached)
        check(git_diff_index_to_tree(repo, &opts, t1, &diff), "Diff");
    else if (t1)
    {
        git_diff_list* diff2;
        check(git_diff_index_to_tree(repo, &opts, t1, &diff), "Diff");
        check(git_diff_workdir_to_index(repo, &opts, &diff2), "Diff");
        check(git_diff_merge(diff, diff2), "Merge diffs");
        git_diff_list_free(diff2);
    }
    else if (cached)
    {
        check(resolve_to_tree(repo, "HEAD", &t1), "looking up HEAD");
        check(git_diff_index_to_tree(repo, &opts, t1, &diff), "Diff");
    }
    else
        check(git_diff_workdir_to_index(repo, &opts, &diff), "Diff");

    //~ if (color >= 0)
        //~ fputs(colors[0], stdout);

    if (compact)
        check(git_diff_print_compact(diff, &color, &printer), "Displaying diff");
    else
        check(git_diff_print_patch(diff, &color, &printer), "Displaying diff");

    //~ if (color >= 0)
        //~ fputs(colors[0], stdout);

    git_diff_list_free(diff);
    git_tree_free(t1);
    git_tree_free(t2);
    git_repository_free(repo);

    return 0;
}
