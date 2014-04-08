# dlibgit

This library provides an idiomatic D interface to the [libgit2](https://github.com/libgit2/libgit2) library. It is based on the [Deimos libgit2 bindings](https://github.com/s-ludwig/libgit2) and currently supports versions 0.19.0 and 0.20.0 of libgit2. This library is available as a [DUB package](http://code.dlang.org/packages/dlibgit).

This project was originally started by Andrej Mitrovic as a set of bindings to libgit2. He since started to implement a D wrapper interface, which was taken up by David Nadlinger. Since some time, Sönke Ludwig has continued the maintainership and completed most of the D API, moving the C bindings to a separate package to make the D API independent of libgit2's development.

## Changes

### v0.50.2 - v0.50.4

- Added `listRemotes`, `GitCommit.parents`, `GitCommit.parentOids`, `GitRemote.autoTag`, and a `SysTime` based overload of `createSignature`
- `GitObject` can now be converted to `GitTree` and to `GitTag`
- Various small fixes and improvements to exception handling in callbacks

### v0.50.1

- Added support for indexes, submodules and tags
- Time values are handled as `SysTime` objects now
- "Upcasts" from `GitObject` to specialized types, such as `GitCommit` are supported now
- `GitSignature` now has getter properties for all fields

### v0.50.0

- The version number has been incremented to be independent of the underlying libgit2 version - dlibgit aims to always support the latest versions of libgit2 under a unified API
- The D interface is about 70% finished
- All C bindings have been removed in favor of the separate Deimos package

### v0.19.0

- The new C-based bindings are now part of the `git.c` package.
- The `_object.d` and `_version.d` files have been renamed to `object_.d` and `version_.d`,
    as this is the usual D convention of naming modules that use D keywords.
- C-based documentation in the header files is now included with the .d files.
- Enums members can now be accessed both with their fully qualified name (e.g. `auto x = git_otype.GIT_OBJ_ANY`),
    and as if they were defined in module scope (e.g. `auto x = GIT_OBJ_ANY`).

## Notes

- Currently the opaque structs are defined as structs with a disabled default ctor, and a disabled
    copy ctor. Ordinarily opaque structs are defined via the `struct S;` syntax, however due to
    a compiler bug ([Issue 10497](http://d.puremagic.com/issues/show_bug.cgi?id=10497)) the
    alternative syntax had to be used.

## Requirements
[DMD] 2.063+.

## Dependencies

- Make sure you either clone with `git clone --recursive`, or if you've already cloned then use:

    $ git submodule init
    $ git submodule update

### Windows:

- A pre-built version of the libgit2 DLL is included with the bindings package

### Posix:

- Get the libgit2 shared library with your package manager
- Or build `libgit2` manually.
- Making sure you install the right version of the libgit2 bindings (e.g. `dub fetch libgit2 --version=0.19.2` or `dub fetch libgit2 --version=0.20.1`)

## Building libgit2 manually

    $ cd <your-folder-of-choice>
    $ git clone git://github.com/libgit2/libgit2.git
    $ cd libgit2
    $ git checkout v0.20.0

- Then follow these instructions: https://github.com/libgit2/libgit2#building-libgit2---using-cmake
- You might need to install zlib if cmake says it's missing (On Posix use your package manager to find the `zlib dev` package).

### Additional Posix notes:

- Make sure the libgit2 shared lib path is in your ld conf file, for example on Linux Mint libgit2 installs to `/usr/local/lib`, so either edit `/etc/ld.so.conf` or run:

    ```
    $ LD_LIBRARY_PATH=/usr/local/lib
    $ export LD_LIBRARY_PATH
    ```

[DMD]: http://dlang.org/download.html

## Building and running samples

### Samples

<span style="color: red">Note that the samples are not yet ported to the new D API and are currently absent from the repository</span>

**diff** sample:

    $ rdmd build.d diff/diff.d
    $ bin\diff.exe .git 2504016ab220b5b 1e8ffc04be048c0

- This will diff the first two commits in **dlibgit**.
- You could pass an absolute path, e.g. `C:/some/git/repo/.git`

**showindex** sample:

    $ rdmd build.d showindex/showindex.d
    $ bin\showindex.exe .git

**git client** sample:
**Note**: This sample has not been ported to v0.19.0 yet.

    $ rdmd build.d samples/network/git.d
    $ bin\git.exe ls-remote git://github.com/s-ludwig/dlibgit.git
    $ bin\git.exe index-pack path\to\.git\objects\pack\abcd1234.pack
    $ bin\git.exe clone git://github.com/s-dludwig/dlibgit.git ../../dlibgit2_clone

- `clone` is not the same as git's `clone` command, it does not deflate git object files.
- `fetch` doesn't currently work due to some bugs in network\fetch.d.
- Replace `path\to` with a valid path for index-pack.

On win32 some libgit functions work with either form of slashes, but you should prefer using forward slashes.

## Usage tips
As a convenience you can import `git.c.all` or `git.c` (with the new 2.064 package import feature) to import all modules at once.

## Documentation

You can use the libgit2 [API] docs. The [general] example is a good read.

[API]: http://libgit2.github.com/libgit2/#v0.20.0
[general]: http://libgit2.github.com/libgit2/ex/v0.20.0/general.html

## See also
- The libgit2 [homepage] and [github] repository.
- [Git Merge 2013] - Current status of libgit2 - conference video.

[homepage]: http://libgit2.github.com/
[github]: https://github.com/libgit2/libgit2/
[Git Merge 2013]: http://www.youtube.com/watch?v=4ZWqr6iih3s

## License
See libgit's [COPYING] file, included in the `src/git/c` folder. Also see the licensing remarks on the [libgit2] github page.

[libgit2]: https://github.com/libgit2/libgit2/
[COPYING]: https://github.com/s-ludwig/dlibgit/blob/master/COPYING

## Disclaimer

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
