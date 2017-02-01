module git.status;
import git.repository;
import git.util;
import deimos.git2.status;
import std.string;

struct GitStatus {
  git_status_t status;
}

GitStatus status(GitRepo repo, string filename) {
  git_status_t status;
  require(git_status_file(cast(uint*)&status, repo.cHandle, filename.toStringz) == 0);
  return GitStatus(status);
}
