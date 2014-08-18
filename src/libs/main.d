module libs.main;

import std.stdio;
import std.range: join;

import libs.expression;

int main(string[] args)
{
    if(args.length == 1)
    {
        writeln("Not enough arguments");
        
        return 1;
    }
    
    auto sentence = args[1 .. $].join(" ");
    
    //writeln("sentence: ", sentence);
    
    auto tokens = tokenize(sentence);
    
    //writeln("tokenized:");
    //
    //foreach(token; tokens)
    //    writeln(token);
    
    auto parsed = parse(tokens);
    
    //writeln("parsed:");
    //
    //foreach(particle; parsed)
    //    writeln(particle);
    //
    //writeln("built:");
    
    string result;
    
    foreach(particle; parsed)
    {
        string built = particle.build;
        
        //if(built.length != 0)
            result ~= built; // ~ " ";
    }
    
    writeln(result);
    
    return 0;
}
