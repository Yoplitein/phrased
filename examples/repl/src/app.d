import std.algorithm;
import std.stdio;
import std.string;

import deimos.linenoise;
import colorize;
import phrased;

/++
    A dictionary that is populated from a file with a simple structure:
    ---
    wordCategory value of this specific word
    otherCategory another word
    ---
+/
class FileDictionary: Dictionary
{
    string[][string] words;
    
    this(string path)
    {
        auto file = File(path);
        uint lineNumber;
        
        foreach(line; file.byLine)
        {
            lineNumber++;
            
            if(line == null)
                continue;
            
            auto firstSpace = line.countUntil(" ");
            
            if(firstSpace == -1)
                throw new Exception("%s: line %s requires a category and a word, separated by a space".format(path, lineNumber));
            
            string category = line[0 .. firstSpace].idup;
            string word = line[firstSpace + 1 .. $].idup;
            
            if(word == null)
                throw new Exception("%s: line %s requires a word".format(path, lineNumber));
            
            words[category] ~= word;
        }
    }
    
    override string lookup(string category)
    {
        import std.random: uniform;
        
        auto list = category in words;
        
        if(list is null)
            return "<error: unknown word category %s>".format(category);
        
        //probably impossible, but can't hurt to check anyway
        if(list.length == 0)
            return "<error: empty category %s>".format(category);
        
        return (*list)[uniform(0, $)];
    }
}

extern(C) void complete(const char *buffer, linenoiseCompletions *completions)
{
    string line = buffer.fromStringz.idup;
    
    if(line == null)
        return;
    
    string lastWord = line.split(" ")[$ - 1];
    string variablePrefix;
    string partialName;
    
    foreach(prefix; ["$(", "$"])
        if(lastWord.startsWith(prefix))
        {
            variablePrefix = prefix;
            partialName = lastWord[prefix.length .. $];
            
            break;
        }
    
    if(variablePrefix != null)
    {
        string[] choices = registered_builtins;
        choices ~= (cast(FileDictionary)defaultDictionary).words.keys;
        
        foreach(name; choices.sort!().uniq)
            if(name.startsWith(partialName))
                linenoiseAddCompletion(completions, (line ~ name[partialName.length .. $]).toStringz);
    }
}

void main()
{
    import core.stdc.stdlib: free;
    
    auto dictionary = new FileDictionary("words.txt");
	defaultDictionary = dictionary;
    
    linenoiseHistoryLoad("history.txt");
    linenoiseSetCompletionCallback(&complete);
    register_builtin(
        "addWord",
        (ArgumentRange arguments)
        {
            if(arguments.length < 3)
                return builtin_error("need at least two arguments: word category and word");
            
            string category = arguments.front.resolve;
            
            arguments.popFront;
            arguments.popFront;
            
            string word = arguments.resolve;
            
            dictionary.words[category] ~= word;
            
            return word;
        }
    );
    
    while(true)
    {
        char *line = linenoise("> ");
        
        if(line is null)
            break;
        
        linenoiseHistoryAdd(line);
        cwritefln(`"%s"`, line.fromStringz.idup.evaluate.color(fg.green));
        free(line);
    }
    
    linenoiseHistorySave("history.txt");
}
