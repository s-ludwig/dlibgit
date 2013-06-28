module git.c.util;

import std.array;
import std.string;

/**
    dlibgit internal utility functions.
*/

/**
    Export all enum members as aliases. This allows enums to be used as types
    and allows its members to be used as if they're defined in module scope.
*/
package mixin template _ExportEnumMembers(E) if (is(E == enum))
{
    mixin(_makeEnumAliases!(E)());
}

/// ditto
package string _makeEnumAliases(E)() if (is(E == enum))
{
    enum enumName = __traits(identifier, E);
    Appender!(string[]) result;

    foreach (string member; __traits(allMembers, E))
        result ~= format("alias %s = %s.%s;", member, enumName, member);

    return result.data.join("\n");;
}

///
unittest
{
    enum enum_type_t
    {
        foo,
        bar,
    }

    mixin _ExportEnumMembers!enum_type_t;

    enum_type_t e1 = enum_type_t.foo;  // ok
    enum_type_t e2 = bar;    // ok
}
