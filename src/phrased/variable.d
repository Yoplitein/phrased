/++
    Interface for managing builtin variables.
    Also includes some default, general purpose builtins.
+/
module phrased.variable;

private
{
    import std.string: format;
    import std.random: uniform;
    import std.typecons: Flag;
    import std.meta: AliasSeq;
    import std.functional: toDelegate;
    
    import phrased: PhrasedException, PhrasedRange;
    import phrased.expression: Node, SequenceNode;
    import phrased.eval;
    import phrased.dictionary;
}

/++
    The signature of a builtin.
+/
alias BuiltinFunction = string delegate(Variables vars, ArgumentRange arguments);

/++
    An input range passed to builtins containing their arguments.
+/
alias ArgumentRange = PhrasedRange!Node;

/++
    A flag to control registration of the default builtins.
+/
alias DefaultBuiltins = Flag!"defaultBuiltins";

/++
    A set of builtins and a dictionary used during template evaluation.
+/
struct Variables
{
    private Dictionary _dictionary;
    private BuiltinFunction[string] _builtins;
    private string currentBuiltin = "NONE";
    
    this(Dictionary dictionary, DefaultBuiltins registerDefaultBuiltins = DefaultBuiltins.yes)
    {
        _dictionary = dictionary;
        
        if(registerDefaultBuiltins)
            foreach(builtin; defaultBuiltins)
                register(builtin.name, builtin.func);
    }
    
    @property Dictionary dictionary()
    {
        return _dictionary;
    }
    
    @property Dictionary dictionary(Dictionary newDictionary)
    {
        return _dictionary = newDictionary;
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
        Evaluate a variable by either running a registered builtin function,
        or looking it up as a word in the dictionary.
    +/
    string lookup(string name, SequenceNode arguments)
    in { assert(_dictionary !is null); }
    body
    {
        if(name in _builtins)
        {
            string lastBuiltin = currentBuiltin;
            currentBuiltin = name;
            scope(exit) currentBuiltin = lastBuiltin;
            auto args = ArgumentRange(arguments.children.data);
            
            return _builtins[name](this, args);
        }
        
        if(arguments.empty)
            return _dictionary.lookup(name);
        else
            return `<error: unknown builtin "%s">`.format(name);
    }
    
    /++
        Helper function for builtins that evaluate to an error.
    +/
    string error(string msg)
    {
        return `<error invoking builtin "%s": %s>`.format(currentBuiltin, msg);
    }
}

/++
    Evaluates an $(SYMBOL_LINK ArgumentRange).
+/
string eval_arguments(ArgumentRange arguments, Variables vars)
{
    import std.array: array;
    
    return new SequenceNode(arguments.array).eval(vars);
}

unittest
{
    import phrased.expression: WordNode;
    
    Variables vars;
    auto args = ArgumentRange([new WordNode("abc"), new WordNode("def")]);
    
    assert(args.eval_arguments(vars) == "abcdef");
    args.popFront;
    assert(args.eval_arguments(vars) == "def");
}

//default builtins

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
string builtin_optional(Variables vars, ArgumentRange arguments)
{
    if(uniform!"[]"(0, 1))
        return arguments.eval_arguments(vars);
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
string builtin_article(Variables vars, ArgumentRange arguments)
{
    if(arguments.length == 0)
        return vars.error("need at least one argument");
    
    auto joined = arguments.eval_arguments(vars);
    
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
string builtin_upper(Variables vars, ArgumentRange arguments)
{
    import std.uni: toUpper;
    
    return arguments.eval_arguments(vars).toUpper;
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
string builtin_lower(Variables vars, ArgumentRange arguments)
{
    import std.uni: toLower;
    
    return arguments.eval_arguments(vars).toLower;
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
    A builtin that evaluates to the name of the current day.
+/
string builtin_today(Variables vars, ArgumentRange arguments)
{
    if(!arguments.empty)
        return vars.error("no arguments expected");
    
    return Clock.currTime.dayOfWeek.name;
}

/++
    A builtin that evaluates to the name of the day tomorrow.
+/
string builtin_tomorrow(Variables vars, ArgumentRange arguments)
{
    if(!arguments.empty)
        return vars.error("no arguments expected");
    
    return Clock.currTime.roll!"days"(1).dayOfWeek.name;
}

/++
    A builtin that evaluates to the name of a random day of the week.
+/
string builtin_day(Variables vars, ArgumentRange arguments)
{
    if(!arguments.empty)
        return vars.error("no arguments expected");
    
    return Clock.currTime.roll!"days"(uniform!"[]"(0, 6)).dayOfWeek.name;
}

private struct DefaultBuiltin
{
    string name;
    BuiltinFunction func;
}

private immutable DefaultBuiltin[] defaultBuiltins;

static this()
{
    import std.exception: assumeUnique;
    
    auto defaultBuiltins = [
        DefaultBuiltin("optional", toDelegate(&builtin_optional)),
        DefaultBuiltin("article", toDelegate(&builtin_article)),
        DefaultBuiltin("upper", toDelegate(&builtin_upper)),
        DefaultBuiltin("lower", toDelegate(&builtin_lower)),
        DefaultBuiltin("today", toDelegate(&builtin_today)),
        DefaultBuiltin("tomorrow", toDelegate(&builtin_tomorrow)),
        DefaultBuiltin("day", toDelegate(&builtin_day)),
    ];
    .defaultBuiltins = defaultBuiltins.assumeUnique;
}

unittest
{
    import phrased.expression;
    
    auto dictionary = new RuntimeDictionary;
    auto vars = Variables(dictionary);
    
    dictionary.add("test", "abc");
    vars.register(
        "testtwo",
        (Variables vars, ArgumentRange args)
        {
            return "def";
        }
    );
    
    string result = "$test $testtwo".lex.parse.eval(vars);
    
    assert(result == "abc def");
}
