module libs.database;

interface Database
{
    string resolve_variable(string name);
}

/+
    Plaintext file database.
    
    Format:
        [section 1]
            word
            word
            ...
        [section 2]
            word
            word
            ...
        ...
+/
class PlaintextDatabase: Database
{
    enum FILE_NAME = "words.txt";
    
    string[][string] words;
    
    this()
    {
        import std.stdio: File;
        import std.regex: ctRegex, matchFirst;
        import std.string: stripRight;
        
        auto sectionRegex = ctRegex!(r"^\[(?P<name>[a-zA-Z ]+)\]$");
        auto lineRegex = ctRegex!(r"^ +(?P<word>.+)$");
        auto file = File(FILE_NAME);
        string section;
        
        while(true)
        {
            string line = file.readln.stripRight;
            
            if(line == "")
                break;
            
            auto sectionMatch = line.matchFirst(sectionRegex);
            
            if(!sectionMatch.empty)
                section = sectionMatch["name"];
            else
            {
                auto lineMatch = line.matchFirst(lineRegex);
                
                if(!lineMatch.empty)
                    words[section] ~= [lineMatch["word"]];
            }
        }
        
        file.close;
    }
    
    override string resolve_variable(string name)
    {
        import std.string: format;
        
        if(name in words)
            return words[name].random_choice;
        else
            return "$(%s)".format(name);
    }
}

class RuntimeDatabase: Database
{
    Database fallback;
    string[][string] words;
    
    this(Database fallback)
    {
        this.fallback = fallback;
    }
    
    override string resolve_variable(string name)
    {
        if(name in words)
            return words[name].random_choice;
        else
            return fallback.resolve_variable(name);
    }
    
    void update(string[][string] words)
    {
        foreach(key; words.keys)
            this.words[key] ~= words[key];
    }
}

string resolve_variable(string name)
{
    return database.resolve_variable(name);
}

private string random_choice(string[] choices)
{
    import std.random: uniform;
    
    return choices[uniform(0, $)];
}

RuntimeDatabase database;

static this()
{
    //TODO: compile-time selection of database driver
    //database = new RuntimeDatabase(new PlaintextDatabase);
}
