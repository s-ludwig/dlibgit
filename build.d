module build;

import std.exception;
import std.range;
import std.file;
import std.path;
import std.process;
import std.string;
import std.stdio;

version(Windows)
{
    string libArg = r"bin\libgit2_implib.lib";
    string binPath = r"bin\";
    enum string exeExt = ".exe";
}
else
{
    string libArg = "-Lbin/ -L-lgit2";
    string binPath = "bin/";
    enum string exeExt = "";
}

void main(string[] args)
{
    args.popFront();
    if (args.empty)
    {
        writeln("Error: Pass a .d file to compile.");
        return;
    }

    string arg = args.front;

    string proj = arg.stripExtension.baseName;
    string outFile = format("%s%s%s", binPath, proj, exeExt);

    string path1 = buildPath(".".absolutePath, "src/git2").buildNormalizedPath;
    string path2 = buildPath(".".absolutePath, "../../src/git2").buildNormalizedPath;

    string dlibgitPath = path1.exists ? path1 : path2;
    dlibgitPath = buildPath(dlibgitPath, "../").buildNormalizedPath;
    enforce(dlibgitPath.exists);

    libArg = buildPath(dlibgitPath, libArg).buildNormalizedPath;
    outFile = buildPath(dlibgitPath, outFile).buildNormalizedPath;

    string cmd = format("rdmd --force --build-only -m32 %s -I%s -of%s %s", libArg, dlibgitPath, outFile, arg);
    system(cmd);
}

