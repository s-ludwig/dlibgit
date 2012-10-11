libgit D binding.

== Requirements ==
    DMD 2.060+.
    
    Windows:
        You're already set.
    
    Posix:
        You need to build the libgit2 shared library (a specific commit is required):
    
        $ git clone -b development git://github.com/libgit2/libgit2.git
        $ cd libgit2 && git checkout acd1700630ea1159a55dc5e8cee12e4a725afe18
        - Follow these instructions: http://libgit2.github.com/#install
        - Make sure the libgit2 shared lib path is in your ld conf file.
          E.g. on Linux Mint libgit2 installs to /usr/local/lib, so either 
          edit /etc/ld.so.conf or do:
          
          $ LD_LIBRARY_PATH=/usr/local/lib
          $ export LD_LIBRARY_PATH

== Building and running samples ==
    $ rdmd build.d samples/diff/diff.d
    $ bin\diff.exe .git 2504016ab220b5b 1e8ffc04be048c0
    
    - ^ That will diff the first two commits in dlibgit.
    - You could pass an absolute path, e.g. C:/some/git/repo/.git
    
    $ rdmd build.d samples/showindex/showindex.d
    $ bin\showindex.exe .git
    
    Some libgit functions work with either form of slashes on win32, but you should
    probably prefer forward slashes.
    
== Note ==
    DLL was built from commit acd1700630ea1159a55dc5e8cee12e4a725afe18 in the development branch. Inline functions were re-created in D because they're not exported. Don't try to use a DLL built from other commits without doing a diff and verifying that the inline functions are still the same in the D version as in C. The libgit2 master branch is out of date and might not compile.

== LICENSE ==
See libgit's COPYING file, included in this repo. I am not a lawyer.

== DISCLAIMER ==

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
