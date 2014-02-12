/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.config;

import deimos.git2.config;

/**
    Priority level of a config file.
    These priority levels correspond to the natural escalation logic
    (from higher to lower) when searching for config entries in git.git.

    todo: fix up the docs here:

    git_config_open_default() and git_repository_config() honor those
    priority levels as well.
*/
enum GitConfigLevel
{
	/** System-wide configuration file; /etc/gitconfig on Linux systems. */
	system = GIT_CONFIG_LEVEL_SYSTEM,

	/** XDG compatible configuration file; typically ~/.config/git/config. */
	xdg = GIT_CONFIG_LEVEL_XDG,

	/**
        User-specific configuration file (also called Global configuration file),
        typically ~/.gitconfig.
    */
    global = GIT_CONFIG_LEVEL_GLOBAL,

	/** Repository specific configuration file - $WORK_DIR/.git/config on non-bare repos. */
	local = GIT_CONFIG_LEVEL_LOCAL,

	/** Application specific configuration file - freely defined by applications. */
	app = GIT_CONFIG_LEVEL_APP,

	/**
        Represents the highest level available config file (i.e. the most
        specific config file available that actually is loaded).
    */
    highest = GIT_CONFIG_HIGHEST_LEVEL,
}
