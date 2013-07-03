## things to do for D wrapper library

- Write a build script that generates docs in the docs folder
- Create .ddoc file for the docs (grab some from H. S. Teoh)
- Move build scripts to build folder
- Create separate version structs for libgit2 and dlibgit
- use https://github.com/libgit2/TestGitRepository for samples
- assert or in blocks should be used to verify arguments (such as strings)
  before calling Git functions since Git itself does not check pointers for null.
  Passing null pointers to Git functions usually results in access violations.
- make build script avoid using -unittest if test\repo dir is missing, and issue
  a warning that the user should update the submodules in order to test the library
- Use checkout commands before testing isHeadDetached and isHeadOrphan to improve
  the sample code.
- Replace static asserts in unittests with normal asserts and calls. We have to
  create several repositories with interesting state before the e.g. walker
  functions can operate on.

## bugs to file to libgit2 (or pulls to make-
- git_repository_discover dosc reference base_path instead of start_path
    - it also seems to mention that if 'acrossFS' is true lookup stops, but it should be if it's false
