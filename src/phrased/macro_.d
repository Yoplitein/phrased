/++
    Interface for managing expression macros.
    Also includes some default, general purpose macros.
    
    Registration of the default macros can be disabled by passing version PHRASED_NO_DEFAULT_MACROS.
+/
module phrased.macro_;

private
{
    import std.string: format;
    
    import phrased: PhrasedException, PhrasedRange;
    import phrased.expression: Node, SequenceNode;
    
    MacroFunction[string] macros;
    string currentMacro;
}

/++
    The signature of a function implementing a macro.
+/
alias MacroFunction = string delegate(ArgumentRange arguments);

/++
    An input range passed to macros containing their arguments.
+/
alias ArgumentRange = PhrasedRange!Node;

/++
    Register a macro.
    
    Params:
        name = name of the macro, as used in expressions
        macroFunc = function to call when this macro is invoked in an expression
        overwrite = whether to overwrite preexisting macros
    
    Throws:
        $(LINK2 phrased.package.html#PhrasedException, PhrasedException) if another macro exists by this name, and overwrite is false
+/
void register_macro(FunctionType)(string name, FunctionType macroFunc, bool overwrite = false)
{
    import std.functional: toDelegate;
    
    if(name in macros && !overwrite)
        throw new PhrasedException("A macro by the name %s already exists".format(name));
    
    macros[name] = macroFunc.toDelegate;
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
    or looking it up as a word in the $(LINK2 phrased.dictionary.html#defaultDictionary, default dictionary).
    
    Throws:
        PhrasedException if the macro is to be resolved as a word and the default dictionary is null
+/
string resolve_macro(string name, SequenceNode arguments)
{
    import phrased.dictionary: defaultDictionary;
    
    if(name in macros)
    {
        currentMacro = name;
        scope(exit) currentMacro = "UNDEFINED";
        auto args = ArgumentRange(arguments.children.data);
        
        return macros[name](args);
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

/++
    Resolves an $(SYMBOL_LINK ArgumentRange) into a string.
+/
string resolve(ArgumentRange arguments)
{
    import std.array: array;
    
    return new SequenceNode(arguments.array).resolve;
}

//default macros

/++
    A macro implementing an optional expression. Nicer syntax for $(TT {expression|}).
    
    Examples:
        ---
        I have $(DOLLAR)(optional far too many )cats.
        ---
        becomes
        ---
        I have cats.
        OR
        I have far too many cats.
        ---
+/
string macro_optional(ArgumentRange arguments)
{
    import std.random: uniform;
    
    if(uniform!"[]"(0, 1))
        return arguments.resolve;
    else
        return "";
}

/++
    A macro that uses the appropriate article for the first word in the arguments.
    
    Examples:
        ---
        $(DOLLAR)(article bear), $(DOLLAR)(article aardvark)
        ---
        becomes
        ---
        a bear, an aardvark
        ---
+/
string macro_article(ArgumentRange arguments)
{
    if(arguments.length == 0)
        return macro_error("need at least one argument");
    
    auto joined = arguments.resolve;
    
    switch(joined[0])
    {
        case 'a':
        case 'A':
        case 'e':
        case 'E':
        case 'i':
        case 'I':
        case 'o':
        case 'O':
        case 'u':
        case 'U':
            return "an " ~ joined;
        default:
            return "a " ~ joined;
    }
}

/++
    A macro that converts its arguments to uppercase.
    
    Examples:
        ---
        $(DOLLAR)(upper Hello, world!)
        ---
        becomes
        ---
        HELLO, WORLD!
        ---
+/
string macro_upper(ArgumentRange arguments)
{
    import std.uni: toUpper;
    
    return arguments.resolve.toUpper;
}

/++
    A macro that converts its arguments to lowercase.
    
    Examples:
        ---
        $(DOLLAR)(lower WHY AM I SHOUTING)
        ---
        becomes
        ---
        why am i shouting
        ---
+/
string macro_lower(ArgumentRange arguments)
{
    import std.uni: toLower;
    
    return arguments.resolve.toLower;
}

private
{
    import std.datetime: Clock, DayOfWeek;
    
    string name(DayOfWeek day)
    {
        final switch(day) with(DayOfWeek)
        {
            case mon:
                return "Monday";
            case tue:
                return "Tuesday";
            case wed:
                return "Wednesday";
            case thu:
                return "Thursday";
            case fri:
                return "Friday";
            case sat:
                return "Saturday";
            case sun:
                return "Sunday";
        }
    }
}

/++
    A macro that resolves to the name of the current day.
+/
string macro_today(ArgumentRange arguments)
{
    if(!arguments.empty)
        return macro_error("no arguments expected");
    
    return Clock.currTime.dayOfWeek.name;
}

/++
    A macro that resolves to the name of the day tomorrow.
+/
string macro_tomorrow(ArgumentRange arguments)
{
    if(!arguments.empty)
        return macro_error("no arguments expected");
    
    return Clock.currTime.roll!"days"(1).dayOfWeek.name;
}

version(PHRASED_NO_DEFAULT_MACROS) {}
else
{
    static this()
    {
        register_macro("optional", &macro_optional);
        register_macro("article", &macro_article);
        register_macro("upper", &macro_upper);
        register_macro("lower", &macro_lower);
        register_macro("today", &macro_today);
        register_macro("tomorrow", &macro_tomorrow);
    }
}
