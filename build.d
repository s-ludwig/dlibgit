module build;

import std.exception;
import std.range;
import std.path;
import std.process;
import std.string;
import std.stdio;

version(Windows)
{
    enum string libArg = r"bin\libgit2.dll.lib";
    enum string binPath = r"bin\";
    enum string exeExt = ".exe";
}
else
{
    enum string libArg = "-Lbin/ -L-lgit2";
    enum string binPath = "bin/";
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

    string cmd = format("rdmd --force --build-only -m32 %s -I. -of%s %s", libArg, outFile, arg);
    system(cmd);
}

