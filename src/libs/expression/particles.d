module libs.expression.particles;

import std.string: format;
import std.random: uniform;

class Particle
{
    string contents;
    
    this(string contents)
    {
        this.contents = contents;
    }
    
    string build()
    {
        return contents;
    }
    
    override string toString()
    {
        return "Particle(\"%s\")".format(contents);
    }
}

class ChoiceParticle: Particle
{
    Particle[] choices;
    
    this()
    {
        super("");
    }
    
    this(Particle[] choices)
    {
        super("");
        
        this.choices = choices;
    }
    
    override string build()
    {
        return choices[uniform!"[]"(0, $ - 1)].build();
    }
    
    override string toString()
    {
        string choiceStr;
        
        foreach(choice; choices)
            choiceStr ~= "    %s\n".format(choice);
        
        if(choiceStr.length != 0)
            choiceStr = choiceStr[0 .. $ - 1];
        
        return "ChoiceParticle(\n%s\n)".format(choiceStr);
    }
}

class VariableParticle: Particle
{
    this(string contents)
    {
        super(contents);
    }
    
    override string build()
    {
        return "<variable of type " ~ contents ~ ">";
    }
    
    override string toString()
    {
        return "VariableParticle(\"%s\")".format(contents);
    }
}

class ParticleSequence: Particle
{
    Particle[] parts;
    
    this()
    {
        super("");
    }
    
    this(Particle[] parts)
    {
        super("");
        
        this.parts = parts;
    }
    
    override string build()
    {
        string result;
        
        foreach(part; parts)
        {
            string built = part.build;
            
            //if(built.length != 0)
                result ~= built;
        }
        
        //if(result.length == 0)
            return result;
        //else
        //    return result[0 .. $ - 1];
    }
    
    override string toString()
    {
        return "ParticleSequence(%s)".format(parts);
    }
    
    void add(Particle particle)
    {
        parts ~= particle;
    }
    
    void pop_last()
    {
        if(parts.length != 0)
            parts = parts[0 .. $ - 1];
    }
}
