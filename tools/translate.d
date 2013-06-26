module test;

import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.path;
import std.exception;
import std.process;
import std.string;
import std.stdio;
import std.typetuple;
import std.typecons;
import std.traits;
import std.range;
import std.regex;

/**
    Helper script which translates header files into D modules.

    Unsupported:
        - typedefs and inline function definitions, these need to be manually ported
        - #define's are not translated
*/

string translate(string input)
{
    input = input.replace(regex(`GIT_EXTERN\(([^)]+)\)`, "g"), "$1");

    input = input.replace("GIT_BEGIN_DECL", "");
    input = input.replace(`#include "`, "import git.c.");
    input = input.replace(`.h"`, ";");
    input = input.replace("import git.c.object;", "import git.c.object_;");
    input = input.replace("import git.c.version;", "import git.c.version_;");

    input = input.replace(`/** @} */`, "");

    input = input.replace("#ifndef", "// #ifndef");
    input = input.replace("#define", "// #define");

    input = input.replace("(void)", "()");
    input = input.replace("const void *", "const(void)* ");
    input = input.replace("unsigned short", "ushort");
    input = input.replace("unsigned char", "ubyte");
    input = input.replace("unsigned int", "uint");
    input = input.replace("unsigned", "uint");
    input = input.replace("**out,", "**out_,");
    input = input.replace("*out,", "*out_,");
    input = input.replace("**out)", "**out_)");
    input = input.replace("*out)", "*out_)");
    input = input.replace(" version;", " version_;");
    input = input.replace(" ref,", "ref_,");
    input = input.replace("*ref)", "*ref_)");
    input = input.replace(" *ref, ", " *ref_, ");
    input = input.replace(" *ref,", " *ref_,");

    input = input.replace("const char **", "const(char)** ");
    input = input.replace("const char *", "const(char)* ");
    input = input.replace("const git_config *", "const(git_config)* ");
    input = input.replace("const git_commit *", "const(git_commit)* ");
    input = input.replace("const git_diff_file *", "const(git_diff_file)* ");
    input = input.replace("const git_oid *", "const(git_oid)* ");
    input = input.replace("const git_blob *", "const(git_blob)* ");
    input = input.replace("const git_object *", "const(git_object)* ");
    input = input.replace("const git_clone_options *", "const(git_clone_options)* ");
    input = input.replace("const git_signature *", "const(git_signature)* ");
    input = input.replace("const git_tree *", "const(git_tree)* ");
    input = input.replace("const git_cvar_map *", "const(git_cvar_map)* ");
    input = input.replace("const git_config_entry *", "const(git_config_entry)* ");
    input = input.replace("const git_error *", "const(git_error)* ");
    input = input.replace("const git_note *", "const(git_note)* ");
    input = input.replace("const git_reference *", "const(git_reference)* ");
    input = input.replace("const git_reflog_entry *", "const(git_reflog_entry)* ");
    input = input.replace("const git_refspec *", "const(git_refspec)* ");
    input = input.replace("const git_strarray *", "const(git_strarray)* ");
    input = input.replace("const git_tree_entry *", "const(git_tree_entry)* ");
    input = input.replace("const git_tag *", "const(git_tag)* ");
    input = input.replace("const git_index *", "const(git_index)* ");
    input = input.replace("const git_index_entry **", "const(git_index_entry)** ");
    input = input.replace("const git_index_entry *", "const(git_index_entry)* ");
    input = input.replace("const git_transfer_progress *", "const(git_transfer_progress)* ");
    input = input.replace("const git_status_options *", "const(git_status_options)* ");
    input = input.replace("const git_merge_tree_opts *", "const(git_merge_tree_opts)* ");
    input = input.replace("const git_status_entry *", "const(git_status_entry)* ");
    input = input.replace("const git_index_name_entry *", "const(git_index_name_entry)* ");
    input = input.replace("const git_index_reuc_entry *", "const(git_index_reuc_entry)* ");

    input = input.replace("struct git_odb *", "git_odb* ");

    input = input.replace("GIT_END_DECL", "");
    input = input.replace("#endif", "//#endif");

    input = input.replace("typedef enum", "enum");
    input = input.replace("typedef struct", "struct");
    input = input.replace("};", "}");

    return input;
}

void main(string[] args)
{
    args.popFront();

    bool force;
    string name;

    foreach (arg; args)
    {
        if (arg == "-force" || arg == "--force")
            force = true;
        else
            name = arg;
    }

    auto str = cast(string)std.file.read(name);

    auto res = str.translate;

    auto app = appender!string();
    app ~= format("module git.c.%s;\n\n", name.stripExtension.baseName);
    app ~= "extern (C):\n\n";
    app ~= res;

    string path = buildPath(".", name.stripExtension.baseName.setExtension(".d"))
        .absolutePath.buildNormalizedPath;
    //~ writeln(path);

    if (!force)
        enforce(!path.exists, format("Won't overwrite file '%s'", path));

    std.file.write(path, app.data);

    executeShell(format("scite %s", path));
}

