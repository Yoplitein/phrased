module libs.main;

import std.stdio;
import std.getopt;
import std.range: join;

import libs.expression;
import libs.database;

void main(string[] args)
{
    string[][string] defines;
    
    void define_handler(string _, string option)
    {
        string key;
        string value;
        bool haveKey;
        
        foreach(character; option)
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
    
    if(args.length == 1)
    {
        stderr.writeln("Not enough arguments");
        
        return;
    }
    
    auto sentence = args[1 .. $].join(" ");
    auto parsed = sentence.parse;
    
    /*foreach(token; parsed)
        writeln(token);*/
    
    writeln(parsed.build);
}
