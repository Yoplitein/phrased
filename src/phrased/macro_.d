/++
    Interface for managing expression macros.
+/
module phrased.macro_;

private
{
    import std.string: format;
    
    import phrased: PhrasedException;
    import phrased.expression: SequenceNode;
    
    MacroFunction[string] macros;
    string currentMacro;
}

/++
    The signature of a function implementing a macro.
+/
alias MacroFunction = string delegate(SequenceNode arguments);

/++
    Register a macro.
    
    Params:
        name = name of the macro, as used in expressions
        macroFunc = function to call when this macro is invoked in an expression
        overwrite = whether to overwrite preexisting macros
    
    Throws:
        $(LINK2 phrased.package.html#PhrasedException PhrasedException) if another macro exists by this name, and overwrite is false
+/
void register_macro(string name, MacroFunction macroFunc, bool overwrite = false)
{
    if(name in macros && !overwrite)
        throw new PhrasedException("A macro by the name %s already exists".format(name));
    
    macros[name] = macroFunc;
}

/++
    Deregister a macro, if it exists.
+/
void deregister_macro(string name)
{
    macros.remove(name);
}

/++
    Resolve a macro into a string by either running a registered macro function,
    or looking it up as a word in the $(LINK2 phrased.dictionary.html#defaultDictionary default dictionary).
    
    Throws:
        PhrasedException if the macro is resolved as a word and the default dictionary is null
+/
string resolve_macro(string name, SequenceNode arguments)
{
    import phrased.dictionary: defaultDictionary;
    
    if(name in macros)
    {
        currentMacro = name;
        scope(exit) currentMacro = "UNDEFINED";
        
        return macros[name](arguments);
    }
    
    if(arguments.empty)
    {
        if(defaultDictionary is null)
            throw new PhrasedException(`Attempted to resolve macro "%s" as a word, but the default dictionary is null`.format(name));
        
        return defaultDictionary.lookup(name);
    }
    else
        return `<error: unknown macro "%s">`.format(name);
}

/++
    Helper function for macros that resolve to an error.
+/
string macro_error(string msg)
{
    return `<error invoking macro "%s": %s>`.format(currentMacro, msg);
}
