# dlibgit - libgit2 D bindings

These are the D bindings to the libgit2 library.

## News
dlibgit has been updated and now targets libgit v0.19.0.

## v0.19.0 Changes

- The new C-based bindings are now part of the `git.c` package.

- The `_object.d` and `_version.d` files have been renamed to `object_.d` and `version_.d`,
    as this is the usual D convention of naming modules that use D keywords.

- C-based documentation in the header files is now included with the .d files.

## Requirements
[DMD] 2.063+.

## Dependencies

### Windows:

- Get the libgit2 DLL from [here](https://github.com/AndrejMitrovic/libgit_bin).
- Or build `libgit2` manually.

### Posix:

- Get the libgit2 shared library with your package manager, making sure you're getting the `0.19.0` release.
- Or build `libgit2` manually.

## Building libgit2 manually

    $ cd <your-folder-of-choice>
    $ git clone git://github.com/libgit2/libgit2.git
    $ cd libgit2
    $ git checkout v0.19.0

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

**diff** sample:

    $ rdmd build.d samples/diff/diff.d
    $ bin\diff.exe .git 2504016ab220b5b 1e8ffc04be048c0

- This will diff the first two commits in **dlibgit**.
- You could pass an absolute path, e.g. `C:/some/git/repo/.git`

**showindex** sample:

    $ rdmd build.d samples/showindex/showindex.d
    $ bin\showindex.exe .git

**git client** sample:
**Note**: This sample has not been ported to v0.19.0 yet.

    $ rdmd build.d samples/network/git.d
    $ bin\git.exe ls-remote git://github.com/AndrejMitrovic/dlibgit.git
    $ bin\git.exe index-pack path\to\.git\objects\pack\abcd1234.pack
    $ bin\git.exe clone git://github.com/AndrejMitrovic/dlibgit.git ../../dlibgit2_clone

- `clone` is not the same as git's `clone` command, it does not deflate git object files.
- `fetch` doesn't currently work due to some bugs in network\fetch.d.
- Replace `path\to` with a valid path for index-pack.

On win32 some libgit functions work with either form of slashes, but you should prefer using forward slashes.

## Usage tips
As a convenience you can import `git.c.all` or `git.c` (with the new 2.064 package import feature) to import all modules at once.

## Documentation

You can use the libgit2 [API] docs. The [general] example is a good read.

[API]: http://libgit2.github.com/libgit2/#v0.19.0
[general]: http://libgit2.github.com/libgit2/ex/v0.19.0/general.html

## See also
- The libgit2 [homepage] and [github] repository.
- [Git Merge 2013] - Current status of libgit2 - conference video.

[homepage]: http://libgit2.github.com/
[github]: https://github.com/libgit2/libgit2/
[Git Merge 2013]: http://www.youtube.com/watch?v=4ZWqr6iih3s

## License
See libgit's [COPYING] file, included in the `src/git/c` folder. Also see the licensing remarks on the [libgit2] github page.

[libgit2]: https://github.com/libgit2/libgit2/
[COPYING]: https://github.com/AndrejMitrovic/dlibgit/blob/master/COPYING

## Disclaimer

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
