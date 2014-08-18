module libs.expression.parser;

import std.stdio;

import libs.expression.particles;
import libs.expression.tokenizer: Token, TokenType;

Particle[] parse(Token[] tokens)
{
    Particle[] result;
    Particle[] choices;
    ParticleSequence currentChoice;
    string currentVariable;
    bool parsingChoice;
    bool parsingVariable;
    
    foreach(token; tokens)
    {
        switch(token.type) with(TokenType)
        {
            case WORD:
                if(parsingVariable)
                {
                    currentVariable ~= token.value ~ " ";
                    
                    break;
                }
                
                if(parsingChoice)
                {
                    currentChoice.add(new Particle(token.value));
                    //currentChoice.add(new Particle(" "));
                    
                    break;
                }
                
                result ~= [new Particle(token.value)];
                
                break;
            case CHOICE_START:
                parsingChoice = true;
                currentChoice = new ParticleSequence;
                
                break;
            case CHOICE_END:
                //currentChoice.pop_last;
                
                parsingChoice = false;
                choices ~= [currentChoice];
                result ~= new ChoiceParticle(choices);
                choices = null;
                currentChoice = null;
                
                break;
            case CHOICE_SEPARATOR:
                //currentChoice.pop_last;
                
                choices ~= [currentChoice];
                currentChoice = new ParticleSequence;
                
                break;
            case VARIABLE_START:
                parsingVariable = true;
                
                break;
            case VARIABLE_END:
                parsingVariable = false;
                
                if(currentVariable.length != 0)
                    currentVariable = currentVariable[0 .. $ - 1];
                
                if(currentVariable.length == 0)
                    throw new Exception("Variable name cannot be blank");
                
                if(parsingChoice)
                    currentChoice.add(new VariableParticle(currentVariable));
                else
                    result ~= [new VariableParticle(currentVariable)];
                
                currentVariable = null;
                
                break;
            default:
                assert(false);
        }
    }
    
    /*if(result.length ~= 0)
        result = re*/
    
    return result;
}
