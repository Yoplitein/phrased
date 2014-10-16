module libs.expression.lexer;

import std.stdio;

enum TokenType
{
    WORD,
    CHOICE_START,
    CHOICE_END,
    CHOICE_SEPARATOR,
    MACRO_START,
    MACRO_END,
}

struct Token
{
    TokenType type;
    string value = null;
}

private struct Buffer
{
    string data;
    size_t index;
    
    this(string data)
    {
        this.data = data;
    }
    
    immutable(char) peek(size_t offset = 0)
    {
        if(index + offset >= data.length)
            return cast(char)-1;
        else
            return data[index + offset];
    }
    
    void seek(size_t offset = 1)
    {
        index += offset;
    }
    
    bool empty()
    {
        return index >= data.length;
    }
    
    /*string toString()
    {
        import std.string: format;
        
        return "Buffer(\"%s\", %s)".format(data, index);
    }*/
}

class LexerError: Exception
{
    this(string msg)
    {
        super(msg);
    }
}

Token[] lex(string expression)
{
    reset(expression);
    
    while(!buffer.empty)
    {
        switch(buffer.peek)
        {
            case ' ':
                push_space;
                
                break;
            case '$':
                //writeln("lex_macro");
                lex_macro;
                
                break;
            case '{':
                //writeln("lex_choice");
                lex_choice;
                
                break;
            default:
                //writeln("lex_word");
                lex_word;
        }
    }
    
    push_word;
    
    return tokens;
}

private int /*charsRead*/ lex_word(bool includeSpace = false)
{
    bool haveWord = true;
    bool pushSpace = false;
    int charsRead;
    
    void complete()
    {
        push_word;
        
        if(pushSpace)
            push_space;
    }
    
    loop: while(haveWord && !buffer.empty)
    {
        switch(buffer.peek)
        {
            case '\\':
                charsRead++;
                
                buffer.seek;
                
                goto default;
            case -1: //EOF
            case ' ':
                if(includeSpace)
                    pushSpace = true;
                
                complete;
                
                break loop;
            case '$':
                if(!inMacro)
                    complete;
                else
                    goto default;
                
                break loop;
            case ')':
                if(inMacro)
                    complete;
                else
                    goto default;
                
                break loop;
            case '{':
                complete;
                
                break loop;
            case '|':
            case '}':
                if(choiceLevel > 0)
                    complete;
                else
                    goto default;
                
                break loop;
            default:
                push_character(buffer.peek);
                
                charsRead++;
        }
        
        buffer.seek;
    }
    
    return charsRead;
}

private void lex_macro()
{
    buffer.seek;
    
    auto firstChar = buffer.peek;
    bool complex = firstChar == '(';
    
    push(TokenType.MACRO_START);
    
    if(complex)
    {
        inMacro = true;
        
        buffer.seek;
        
        while(buffer.peek != ')')
            if(lex_word(true) == 0)
                throw new LexerError("unterminated macro");
        
        buffer.seek;
        
        inMacro = false;
    }
    else
        lex_word;
    
    push(TokenType.MACRO_END);
}

private void lex_choice()
{
    buffer.seek;
    push(TokenType.CHOICE_START);
    
    choiceLevel++;
    
    loop: while(true)
    {
        switch(buffer.peek)
        {
            case '\\':
                goto default;
            case -1: //probably won't ever happen but just for safety's sake
                throw new LexerError("unterminated choice expression");
            case '$':
                lex_macro;
                
                break;
            case '|':
                push(TokenType.CHOICE_SEPARATOR);
                buffer.seek;
                
                goto default;
            case '{':
                lex_choice;
                
                break;
            case '}':
                buffer.seek;
                
                break loop;
            default:
                if(lex_word(true) == 0)
                    throw new LexerError("unterminated choice expression");
        }
    }
    
    push(TokenType.CHOICE_END);
    
    choiceLevel--;
}

private void push(TokenType type, string value = "")
{
    tokens ~= [Token(type, value)];
    //writefln(`pushing Token(%s, "%s")`, type, value);
}

private void push_word()
{
    if(currentWord != "")
        push(TokenType.WORD, currentWord);
    
    currentWord = null;
}

private void push_character(char chr)
{
    currentWord ~= chr;
}

private void push_space()
{
    currentWord ~= " ";
    
    push_word;
    buffer.seek;
}

private void reset(string expression)
{
    tokens = null;
    currentWord = null;
    inMacro = false;
    choiceLevel = 0;
    buffer = Buffer(expression);
}

private Token[] tokens;
private string currentWord;
private bool inMacro;
private int choiceLevel;
private Buffer buffer;

/*Token[] lex(string format)
{
    Token[] result;
    string part;
    bool escape;
    int choiceLevel;
    int macroLevel;
    
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
                choiceLevel++;
                
                break;
            case '}':
                if(escape || choiceLevel <= 0)
                    goto default;
                
                add_part();
                
                result ~= [Token(CHOICE_END)];
                choiceLevel--;
                
                break;
            case '|':
                if(escape || choiceLevel > 0 || macroLevel > 0)
                    goto default;
                
                add_part();
                
                result ~= [Token(CHOICE_SEPARATOR)];
                
                break;
            case '$':
                if(escape || macroLevel > 0)
                    goto default;
                
                add_part();
                
                macroLevel++;
                result ~= [Token(MACRO_START)];
                
                break;
            case '(':
                if(macroLevel > 0)
                    break;
                else
                    goto default;
            case ')':
                if(macroLevel <= 0)
                    goto default;
                
                add_part();
                
                result ~= [Token(MACRO_END)];
                macroLevel--;
                
                break;
            default:
                part ~= character;
                escape = false;
        }
    }
    
    if(escape || choiceLevel < 0 || macroLevel < 0)
        throw new Exception("Unterminated escape, choice or variable expression");
    
    add_part();
    
    return result;
}*/

version(none) 
{
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
        assert(lex("$abc") == [
            Token(MACRO_START),
            Token(WORD, "abc"),
            Token(MACRO_END),
        ]);
        assert(lex("$(abc)") == [
            Token(MACRO_START),
            Token(WORD, "abc"),
            Token(MACRO_END),
        ]);
        assert(lex("$(abc 123)") == [
            Token(MACRO_START),
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
            Token(MACRO_END),
        ]);
        assert(lex("pre$(abc 123)") == [
            Token(WORD, "pre"),
            Token(MACRO_START),
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
            Token(MACRO_END),
        ]);
        assert(lex("$(abc 123)fix") == [
            Token(MACRO_START),
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
            Token(MACRO_END),
            Token(WORD, "fix"),
        ]);
        assert(lex("pre$(abc 123)fix") == [
            Token(WORD, "pre"),
            Token(MACRO_START),
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
            Token(MACRO_END),
            Token(WORD, "fix"),
        ]);
        assert(lex("pre$((abc 123)fix") == [
            Token(WORD, "pre"),
            Token(MACRO_START),
            Token(WORD, "(abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
            Token(MACRO_END),
            Token(WORD, "fix"),
        ]);
        assert(lex("pre$(abc 123\\))fix") == [
            Token(WORD, "pre"),
            Token(MACRO_START),
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123)"),
            Token(MACRO_END),
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
            Token(MACRO_START),
            Token(WORD, "abc"),
            Token(WORD, " "),
            Token(WORD, "123"),
            Token(MACRO_END),
            Token(CHOICE_END),
        ]);
        assert(lex("{$(abc|123)|456}") == [
            Token(CHOICE_START),
            Token(MACRO_START),
            Token(WORD, "abc|123"),
            Token(MACRO_END),
            Token(CHOICE_SEPARATOR),
            Token(WORD, "456"),
            Token(CHOICE_END),
        ]);
    }
}
}
