/++
    Interface for looking up words of a type (referred to as the category) from a dictionary.
+/
module phrased.dictionary;

private
{
    import std.string: format;
}

/++
    A dictionary is an object that can return words from certain categories.
+/
interface Dictionary
{
    /++
        The sole method of a Dictionary. Returns a single word from the given category.
        
        If the category does not exist, or is empty, it is recommended to return a string of the form
        $(TT &lt;error: unknown category "categoryName"&gt;), but not required.
    +/
    string lookup(string category);
}

/++
    A dictionary that returns error messages for any category of word that is looked up.
+/
class NullDictionary: Dictionary
{
    enum errorMessage = `<error: looked up word of category "%s" from a NullDictionary>`;
    
    ///
    this() {}
    
    ///See $(SYMBOL_LINK Dictionary.lookup)
    override string lookup(string category)
    {
        return errorMessage.format(category);
    }
}

/++
    A basic dictionary that looks up words in memory, falling back to another dictionary
    if a requested category has not been populated.
    
    Useful for variables that change between expression evaluations
    (such as the time, date, a person's name, etc.),
    or constructing a dictionary in code rather than from, say, a database or text file.
+/
class RuntimeDictionary: Dictionary
{
    enum errorMessage = `<error: unknown word category "%s">`;
    
    Dictionary fallback; ///The dictionary that is used instead when an unknown category is looked up
    string[][string] definitions;
    
    /++
        Construct with an instance of $(SYMBOL_LINK NullDictionary) as the fallback.
    +/
    this()
    {
        fallback = new NullDictionary;
    }
    
    /++
        Construct with a user-supplied dictionary as the fallback.
    +/
    this(Dictionary fallback)
    {
        this.fallback = fallback;
    }
    
    void add(string category, string value)
    {
        definitions[category] ~= value;
    }
    
    /++
        Clear a certain category of words.
    +/
    void clear(string category)
    {
        definitions.remove(category);
    }
    
    /++
        Clear all definitions.
    +/
    void clear()
    {
        foreach(key; definitions.keys)
            definitions.remove(key);
    }
    
    ///See $(SYMBOL_LINK Dictionary.lookup)
    override string lookup(string category)
    {
        import std.random: uniform;
        
        auto list = category in definitions;
        
        if(list is null || list.length == 0)
            return fallback.lookup(category);
        
        return (*list)[uniform(0, $)];
    }
}

unittest
{
    auto dict = new RuntimeDictionary(new NullDictionary);
    
    dict.add("ABC", "abc");
    dict.add("DEF", "def");
    assert(dict.lookup("ABC") == "abc");
    assert(dict.lookup("DEF") == "def");
    assert(dict.lookup("abc") == NullDictionary.errorMessage.format("abc"));
    dict.clear("ABC");
    assert(dict.lookup("ABC") == NullDictionary.errorMessage.format("ABC"));
    dict.clear;
    assert(dict.lookup("DEF") == NullDictionary.errorMessage.format("DEF"));
}
