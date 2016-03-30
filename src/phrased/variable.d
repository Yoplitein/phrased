/++
    Interface for managing builtin variables.
    Also includes some default, general purpose builtins.
    
    Registration of the default builtins can be disabled by passing version PHRASED_NO_DEFAULT_BUILTINS.
+/
module phrased.variable;

private
{
    import std.string: format;
    import std.random: uniform;
    
    import phrased: PhrasedException, PhrasedRange;
    import phrased.expression: Node, SequenceNode;
    import phrased.eval;
    import phrased.dictionary;
}

/++
    The signature of a builtin.
+/
alias BuiltinFunction = string delegate(ArgumentRange arguments);

/++
    An input range passed to builtins containing their arguments.
+/
alias ArgumentRange = PhrasedRange!Node;

/++
    A set of builtins and a dictionary used during template evaluation.
+/
struct Variables
{
    private Dictionary _dictionary;
    private BuiltinFunction[string] _builtins;
    private string currentBuiltin = "NONE";
    
    this(Dictionary dictionary)
    {
        _dictionary = dictionary;
    }
    
    /++
        Register a builtin.
        
        Params:
            name = name of the builtin, as used in expressions
            builtinFunc = function to call when this builtin is invoked in an expression
            overwrite = whether to overwrite preexisting builtins
        
        Throws:
            $(LINK2 phrased.package.html#PhrasedException, PhrasedException) if another builtin exists by this name, and overwrite is false
    +/
    void register(FunctionType)(string name, FunctionType builtinFunc, bool overwrite = false)
    {
        import std.functional: toDelegate;
        
        if(name in _builtins && !overwrite)
            throw new PhrasedException("A builtin by the name %s already exists".format(name));
        
        _builtins[name] = builtinFunc.toDelegate;
    }
    
    /++
        Deregister a builtin, if it exists.
    +/
    void deregister(string name)
    {
        _builtins.remove(name);
    }
    
    /++
        Returns a list of the names of registered builtins.
    +/
    @property string[] builtins()
    {
        return _builtins.keys;
    }
    
    /++
        Resolve a variable into a string by either running a registered builtin function,
        or looking it up as a word in the $(LINK2 phrased.dictionary.html#defaultDictionary, default dictionary).
        
        Throws:
            PhrasedException if the default dictionary is null
    +/
    string resolve(string name, SequenceNode arguments)
    {
        import phrased.dictionary: defaultDictionary;
        
        if(name in _builtins)
        {
            string lastBuiltin = currentBuiltin;
            currentBuiltin = name;
            scope(exit) currentBuiltin = lastBuiltin;
            auto args = ArgumentRange(arguments.children.data);
            
            return _builtins[name](args);
        }
        
        if(arguments.empty)
        {
            if(defaultDictionary is null)
                throw new PhrasedException(`Attempted to resolve variable "%s" as a word, but the default dictionary is null`.format(name));
            
            return defaultDictionary.lookup(name);
        }
        else
            return `<error: unknown builtin "%s">`.format(name);
    }
    
    /++
        Helper function for builtins that resolve to an error.
    +/
    string error(string msg)
    {
        return `<error invoking builtin "%s": %s>`.format(currentBuiltin, msg);
    }
}

/++
    Resolves an $(SYMBOL_LINK ArgumentRange) into a string.
+/
string resolve(ArgumentRange arguments)
{
    import std.array: array;
    
    return new SequenceNode(arguments.array).eval;
}

unittest
{
    import phrased.expression: WordNode;
    
    auto args = ArgumentRange([new WordNode("abc"), new WordNode("def")]);
    
    assert(args.resolve == "abcdef");
    args.popFront;
    assert(args.resolve == "def");
}

//default builtins

version(none):
/++
    A builtin implementing an optional expression. Nicer syntax for $(TT {expression|}).
    
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
string builtin_optional(ArgumentRange arguments)
{
    if(uniform!"[]"(0, 1))
        return arguments.resolve;
    else
        return "";
}

/++
    A builtin that uses the appropriate article for the first word in the arguments.
    
    Examples:
        ---
        $(DOLLAR)(article bear), $(DOLLAR)(article aardvark)
        ---
        becomes
        ---
        a bear, an aardvark
        ---
+/
string builtin_article(ArgumentRange arguments)
{
    if(arguments.length == 0)
        return builtin_error("need at least one argument");
    
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
    A builtin that converts its arguments to uppercase.
    
    Examples:
        ---
        $(DOLLAR)(upper Hello, world!)
        ---
        becomes
        ---
        HELLO, WORLD!
        ---
+/
string builtin_upper(ArgumentRange arguments)
{
    import std.uni: toUpper;
    
    return arguments.resolve.toUpper;
}

/++
    A builtin that converts its arguments to lowercase.
    
    Examples:
        ---
        $(DOLLAR)(lower WHY AM I SHOUTING)
        ---
        becomes
        ---
        why am i shouting
        ---
+/
string builtin_lower(ArgumentRange arguments)
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
    A builtin that resolves to the name of the current day.
+/
string builtin_today(ArgumentRange arguments)
{
    if(!arguments.empty)
        return builtin_error("no arguments expected");
    
    return Clock.currTime.dayOfWeek.name;
}

/++
    A builtin that resolves to the name of the day tomorrow.
+/
string builtin_tomorrow(ArgumentRange arguments)
{
    if(!arguments.empty)
        return builtin_error("no arguments expected");
    
    return Clock.currTime.roll!"days"(1).dayOfWeek.name;
}

/++
    A builtin that resolves to the name of a random day of the week.
+/
string builtin_day(ArgumentRange arguments)
{
    if(!arguments.empty)
        return builtin_error("no arguments expected");
    
    return Clock.currTime.roll!"days"(uniform!"[]"(0, 6)).dayOfWeek.name;
}

version(PHRASED_NO_DEFAULT_BUILTINS) {}
else
{
    static this()
    {
        register_builtin("optional", &builtin_optional);
        register_builtin("article", &builtin_article);
        register_builtin("upper", &builtin_upper);
        register_builtin("lower", &builtin_lower);
        register_builtin("today", &builtin_today);
        register_builtin("tomorrow", &builtin_tomorrow);
        register_builtin("day", &builtin_day);
    }
}
