module libs.expression.lexer;

private
{
    import std.stdio;
    
    import libs.util;
}

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

class LexerException: Exception
{
    this(string msg)
    {
        super(msg);
    }
}

Token[] lex(string expression)
{
    reset(expression);
    
    while(!buffer.finished)
    {
        switch(buffer.peek)
        {
            case ' ':
                push_space;
                
                break;
            case '$':
                lex_macro;
                
                break;
            case '{':
                lex_choice;
                
                break;
            default:
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
    
    loop: while(haveWord && !buffer.finished)
    {
        switch(buffer.peek)
        {
            case '\\':
                charsRead++;
                
                buffer.advance;
                
                goto default;
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
        
        buffer.advance;
    }
    
    return charsRead;
}

private void lex_macro()
{
    buffer.advance;
    
    auto firstChar = buffer.peek;
    bool complex = firstChar == '(';
    
    push(TokenType.MACRO_START);
    
    if(complex)
    {
        //[spacing intensifies]
        inMacro = true;
        
        buffer.advance;
        
        while(buffer.peek != ')')
            if(lex_word(true) == 0)
                throw new LexerException("unterminated macro");
        
        buffer.advance;
        
        inMacro = false;
    }
    else
        lex_word;
    
    push(TokenType.MACRO_END);
}

private void lex_choice()
{
    buffer.advance;
    push(TokenType.CHOICE_START);
    
    choiceLevel++;
    
    loop: while(true)
    {
        switch(buffer.peek)
        {
            case '\\':
                goto default;
            /*case BUFFER_FINISHED: //probably won't ever happen but just for safety's sake
                throw new LexerException("unterminated choice expression");*/
            case '$':
                lex_macro;
                
                break;
            case '|':
                push(TokenType.CHOICE_SEPARATOR);
                buffer.advance;
                
                goto default;
            case '{':
                lex_choice;
                
                break;
            case '}':
                buffer.advance;
                
                break loop;
            default:
                if(lex_word(true) == 0)
                    throw new LexerException("unterminated choice expression");
        }
    }
    
    push(TokenType.CHOICE_END);
    
    choiceLevel--;
}

private void push(TokenType type, string value = "")
{
    tokens ~= [Token(type, value)];
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
    buffer.advance;
}

private void reset(string expression)
{
    tokens = null;
    currentWord = null;
    inMacro = false;
    choiceLevel = 0;
    buffer = typeof(buffer)(expression);
}

//TODO: unittests

private Token[] tokens;
private string currentWord;
private bool inMacro;
private int choiceLevel;
private Buffer!(immutable(char)) buffer;
