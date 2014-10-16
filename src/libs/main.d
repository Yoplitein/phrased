module libs.main;

import std.stdio;
import std.getopt;
import std.range: join;

import libs.expression;
import libs.database;

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
    auto lexed = r"word\\\ word $var word $(macro arg) word {a|b{c|d{e|f}}} word".lex;
    
    writeln("!!!!! lex complete !!!!!");
    
    foreach(token; lexed)
        writefln(`%11s: "%s"`, token.type, token.value);
}
