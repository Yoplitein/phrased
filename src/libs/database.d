module libs.database;

import std.stdio;
import std.string: format;
import std.random: uniform;

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
        if(name in words)
            return words[name].choice;
        else
            return "$(%s)".format(name);
    }
}

string resolve_variable(string name)
{
    return database.resolve_variable(name);
}

private string choice(string[] choices)
{
    return choices[uniform(0, $)];
}

private Database database;

static this()
{
    //TODO: compile-time selection of database driver
    database = new PlaintextDatabase;
}
