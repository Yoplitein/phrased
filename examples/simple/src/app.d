import std.stdio;

import phrased;

void main()
{
	auto dictionary = new RuntimeDictionary; //allows for words to be added at runtime
    defaultDictionary = dictionary; //the macro resolver uses this to look up words
    
    dictionary.add("object", "world");
    dictionary.add("object", "keyboard");
    dictionary.add("object", "baguette");
    dictionary.add("adjective", "shiny");
    dictionary.add("adjective", "obtuse");
    dictionary.add("adjective", "purple");
    register_builtin(
        "uniform",
        (ArgumentRange arguments)
        {
            import std.conv: ConvException, to;
            import std.random: uniform;
            import std.string: format;
            
            if(arguments.length != 3) //the space after the macro name is dropped, but any subsequent spaces are included
                return builtin_error("expected two arguments, minimum value and maximum value");
            
            int min;
            int max;
            
            //arguments may resolve differently each call
            //(e.g. if they're made up of choice expressions, further macros, etc.)
            //so their values should be saved if used more than once
            string minStr = arguments.front.resolve;
            
            arguments.popFront; //pop the first argument
            arguments.popFront; //pop the space
            
            string maxStr = arguments.front.resolve;
            
            try
                min = minStr.to!int;
            catch(ConvException)
                return builtin_error(`"%s" is not a number`.format(minStr));
            
            
            try
                max = maxStr.to!int;
            catch(ConvException)
                return builtin_error(`"%s" is not a number`.format(maxStr));
            
            if(min > max || min == max)
                return builtin_error("min must be less than max");
            
            return uniform(min, max).to!string;
        }
    );
    
    enum expression = "{hello|greetings|'sup} $(optional $adjective )$(object)! my favorite {number is $(uniform 1 15)|color is {red|blue|green|purple|orange}|language is {D|C|C++}}.";
    
    writeln(evaluate(expression)); //evaluate lexes, parses and resolves the expression into one of the many possible output strings
}
