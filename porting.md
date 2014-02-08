Fully ported modules:

- git.c.common
- git.c.oid
- git.c.trace
- git.c.ignore (folded into GitRepo)
- git.c.types

Partially ported modules:

- git.c.config
- git.c.repository (dependencies on other APIs not yet ported)
- git.c.version_

Doesn't need porting:

- git.c.errors (using exceptions)
- git.c.threads (default init/deinit happens in shared module ctor/dtor)
- git.c.message (just one prettifier function)
