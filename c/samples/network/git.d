module git;

import git2.all;

import std.zlib;
import core.thread;
import std.array;
import std.algorithm;
import std.concurrency;
import std.conv;
import std.file;
import std.stdio;
import std.string;
import std.range;
import std.exception;
import std.path;

import common;
import fetch;
import clone;
import ls_remote;
import index_pack;

struct Command
{
	string name;
	git_cb fn;
}

Command[] commands = 
[
	{"ls-remote", &run_ls_remote},
	{"fetch", &run_fetch},
	{"clone", &do_clone},
	{"index-pack", &run_index_pack},
	{ null, null}
];

int run_command(git_cb fn, int argc, string[] args)
{
	int error;
	git_repository *repo;

    // Before running the actual command, create an instance of the local
    // repository and pass it to the function.
    error = git_repository_open(&repo, ".git");
	if (error < 0)
		repo = null;

	// Run the command. If something goes wrong, print the error message to stderr
	error = fn(repo, argc, args);
	if (error < 0) 
    {
		if (giterr_last() == null)
			writeln("Error without message");
		else
			printf("Bad news:\n %s\n", giterr_last().message);
	}

	if (repo)
		git_repository_free(repo);

	return !!error;
}

int main(string[] args)
{
	int i;

	if (args.length < 2) 
    {
		writefln("usage: %s <cmd> [repo]\n", args[0]);
		return 1;
	}

	for (i = 0; commands[i].name != null; ++i) 
    {
		if (args[1] == commands[i].name)
        {
            args.popFront();
			return run_command(commands[i].fn, args.length, args);
        }
	}

	writeln("Command not found: %s\n", args[1]);
	return 0;
}

/+ 
enum Search : SpanMode
{
     deep = SpanMode.depth
    ,wide = SpanMode.breadth
    ,flat = SpanMode.shallow
}

string[] fileList(string root, string ext, Search search = Search.flat)
{
    string[] result;
    
    if (!exists(root))
    {
        writefln("Warning: %s dir not found.", root);
        return null;
    }
    
    foreach (string entry; dirEntries(root, cast(SpanMode)search))
    {
        if (entry.isFile && entry.extension == ext)
            result ~= entry;
    }
    
    return result;
}

void main(string[] args)
{
    if (args.length < 2)
    {
        writeln("Error: Pass the path to a git objects directory.");
        return;
    }
    
    foreach (file; fileList(args[1], "", Search.deep))
    {
        byte[] bytes = cast(byte[])std.file.read(file);
        char[] text = cast(char[])uncompress(bytes);
        
        if (text.startsWith("commit"))
        {
            sizediff_t nulByte = text.countUntil(0);
            if (nulByte != -1)
            {
                writefln("-- %s --\n%s", text[0 .. nulByte], text[nulByte+1 .. $]);
            }
        }
    }
} +/
