import std.file;
import std.path;

import git.blob;
import git.checkout;
import git.commit;
import git.index;
import git.merge;
import git.oid;
import git.repository;
import git.signature;
import git.tree;
import git.types;

pragma(lib, "git2");

GitTree addDir(ref GitRepo repo, string path)
{
	auto tb = createTreeBuilder();
	foreach (de; dirEntries(path, SpanMode.shallow))
	{
		GitOid oid = de.isDir ? repo.addDir(de.name).id : repo.createBlob(cast(ubyte[])de.name.read());
		tb.insert(de.baseName, oid, de.isDir ? GitFileModeType.tree : GitFileModeType.blob);
	}
	return repo.lookupTree(tb.write(repo));
}

void forceEmptyDirectory(string dir)
{
	if (dir.exists)
		dir.rmdirRecurse();
	dir.mkdir();
}

void main()
{
	enum repoPath = "test-repo";
	repoPath.forceEmptyDirectory();
	auto repo = initRepository(repoPath, OpenBare.no);

	enum dataPath = "test-data";
	dataPath.forceEmptyDirectory();
	write(dataPath ~ "/a", "a\nb\nc\nd\ne");
	auto baseTree = repo.addDir(dataPath);

	write(dataPath ~ "/a", "a\nb2\nc\nd\ne");
	auto branch1 = repo.addDir(dataPath);

	write(dataPath ~ "/a", "a\nb\nc\nd2\ne");
	auto branch2 = repo.addDir(dataPath);

	enum workPath = "test-work";
	workPath.forceEmptyDirectory();
	repo.setWorkPath(workPath);

	auto index = repo.mergeTrees(baseTree, branch1, branch2);
	enforce(!index.hasConflicts, "Conflict detected");

	auto oid = index.writeTree(repo);
	GitCheckoutOptions opts = {strategy : GitCheckoutStrategy.force};
	repo.checkout(repo.lookupTree(oid), opts);

	assert(readText(workPath ~ "/a") == "a\nb2\nc\nd2\ne");
}
