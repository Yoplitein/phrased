module libs.expression.lexer;

import std.string: format;
import std.random: uniform;

enum TokenType
{
    WORD,
    CHOICE_START,
    CHOICE_END,
    CHOICE_SEPARATOR,
    VARIABLE_START,
    VARIABLE_END,
}

struct Token
{
    TokenType type;
    string value = null;
}

Token[] lex(string format)
{
    Token[] result;
    string part;
    bool escape;
    bool haveChoice;
    bool haveVariable;
    
    void add_part()
    {
        if(part != "")
            result ~= [Token(TokenType.WORD, part)];
        
        part = null;
    }
    
    foreach(character; format)
    {
        switch(character) with(TokenType)
        {
            case ' ':
                add_part();
                
                result ~= [Token(TokenType.WORD, " ")];
                
                break;
            case '\\':
                if(escape)
                    goto default;
                
                escape = true;
                
                break;
            case '{':
                if(escape)
                    goto default;
                
                add_part();
                
                result ~= [Token(CHOICE_START)];
                haveChoice = true;
                
                break;
            case '}':
                if(escape || !haveChoice)
                    goto default;
                
                add_part();
                
                result ~= [Token(CHOICE_END)];
                haveChoice = false;
                
                break;
            case '|':
                if(escape || !haveChoice || haveVariable)
                    goto default;
                
                add_part();
                
                result ~= [Token(CHOICE_SEPARATOR)];
                
                break;
            case '$':
                if(escape || haveVariable)
                    goto default;
                
                add_part();
                
                haveVariable = true;
                result ~= [Token(VARIABLE_START)];
                
                break;
            case '(':
                if(haveVariable)
                    break;
                else
                    goto default;
            case ')':
                if(!haveVariable)
                    goto default;
                
                add_part();
                
                result ~= [Token(VARIABLE_END)];
                haveVariable = false;
                
                break;
            default:
                part ~= character;
                escape = false;
        }
    }
    
    if(escape || haveChoice || haveVariable)
        throw new Exception("Unterminated escape, choice or variable expression");
    
    add_part();
    
    return result;
}

unittest
{
    with(TokenType)
    {
        //basic words
        assert(lex("abc") == [
            Token(WORD, "abc"),
        ]);
        assert(lex("abc 123") == [
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
        ]);
        
        //choices
        assert(lex("{abc}") == [
            Token(CHOICE_START),
            Token(WORD, "abc"),
            Token(CHOICE_END),
        ]);
        assert(lex("{abc|123}") == [
            Token(CHOICE_START),
            Token(WORD, "abc"),
            Token(CHOICE_SEPARATOR),
            Token(WORD, "123"),
            Token(CHOICE_END),
        ]);
        assert(lex("{abc 123}") == [
            Token(CHOICE_START),
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
            Token(CHOICE_END),
        ]);
        
        //variables
        assert(lex("$(abc)") == [
            Token(VARIABLE_START),
            Token(WORD, "abc"),
            Token(VARIABLE_END),
        ]);
        assert(lex("$(abc 123)") == [
            Token(VARIABLE_START),
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
            Token(VARIABLE_END),
        ]);
        assert(lex("pre$(abc 123)") == [
            Token(WORD, "pre"),
            Token(VARIABLE_START),
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
            Token(VARIABLE_END),
        ]);
        assert(lex("$(abc 123)fix") == [
            Token(VARIABLE_START),
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
            Token(VARIABLE_END),
            Token(WORD, "fix"),
        ]);
        assert(lex("pre$(abc 123)fix") == [
            Token(WORD, "pre"),
            Token(VARIABLE_START),
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
            Token(VARIABLE_END),
            Token(WORD, "fix"),
        ]);
        
        //escapes
        assert(lex("\\{") == [
            Token(WORD, "{"),
        ]);
        assert(lex("\\$") == [
            Token(WORD, "$"),
        ]);
        assert(lex("\\\\") == [
            Token(WORD, "\\"),
        ]);
        assert(lex("\\{abc|123}") == [
            Token(WORD, "{abc|123}"),
        ]);
        assert(lex("{abc\\|123}") == [
            Token(CHOICE_START),
            Token(WORD, "abc|123"),
            Token(CHOICE_END),
        ]);
        assert(lex("{abc|123\\}}") == [
            Token(CHOICE_START),
            Token(WORD, "abc"),
            Token(CHOICE_SEPARATOR),
            Token(WORD, "123}"),
            Token(CHOICE_END),
        ]);
        assert(lex("pre\\$(abc 123)fix") == [
            Token(WORD, "pre$(abc"),
            Token(WORD, " "),
            Token(WORD, "123)fix"),
        ]);
        
        //unterminated expressions
        try
        {
            lex("\\");
            assert(false);
        }
        catch(Exception err) {}
        
        try
        {
            lex("{");
            assert(false);
        }
        catch(Exception err) {}
        
        try
        {
            lex("$(");
            assert(false);
        }
        catch(Exception err) {}
        
        //variables in choices
        assert(lex("{$(abc 123)}") == [
            Token(CHOICE_START),
            Token(VARIABLE_START),
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
            Token(VARIABLE_END),
            Token(CHOICE_END),
        ]);
        assert(lex("{$(abc|123)|456}") == [
            Token(CHOICE_START),
            Token(VARIABLE_START),
            Token(WORD, "abc|123"),
            Token(VARIABLE_END),
            Token(CHOICE_SEPARATOR),
            Token(WORD, "456"),
            Token(CHOICE_END),
        ]);
    }
}
