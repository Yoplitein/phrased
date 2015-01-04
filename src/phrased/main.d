module phrased.main;

import std.stdio;
import std.getopt;
import std.range: join;

import phrased.expression;
import phrased.database;

void main(string[] args)
{
    string[][string] defines;
    
    void define_handler(string optionName, string optionValue)
    {
        string key;
        string value;
        bool haveKey;
        
        foreach(character; optionValue)
        {
            if(!haveKey && character == '=')
            {
                haveKey = true;
                
                continue;
            }
            
            if(haveKey)
                value ~= character;
            else
                key ~= character;
        }
        
        defines[key] ~= [value];
    }
    
    getopt(
        args,
        config.passThrough,
        "define", &define_handler
    );
    
    database.update(defines);
    
    /*if(args.length == 1)
    {
        stderr.writeln("Not enough arguments");
        
        return;
    }
    
    auto sentence = args[1 .. $].join(" ");
    auto lexed = sentence.lex;
    auto parsed = sentence.parse;
    
    foreach(token; lexed)
        writeln(token);
    
    foreach(particle; parsed)
        writeln(particle);
    
    writeln(parsed.build);*/
    
}
