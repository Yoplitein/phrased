module libs.expression.particles;

import std.string: format;

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
        import std.random: uniform;
        
        return choices[uniform!"[]"(0, $ - 1)].build();
    }
    
    override string toString()
    {
        return "ChoiceParticle(%s)".format(choices);
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
        import libs.database;
        
        return resolve_variable(contents);
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
            result ~= part.build;
        
        return result;
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
